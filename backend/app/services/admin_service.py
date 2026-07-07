import asyncio
import csv
import io
import random
import string
from datetime import datetime, timezone
from typing import Any

from pymongo import ReturnDocument

from app.core.identifiers import parse_object_id
from app.core.config import settings
from app.core.websocket_manager import manager
from app.db.mongo import get_database
from app.db.redis_client import invalidate_event_cache
from app.exceptions.handlers import AppException
from app.models.event import EventCreate, EventInDB, EventResponse, EventUpdate
from app.models.user import UserResponse


class AdminService:
    @staticmethod
    async def get_events(
        admin_id: str,
        page: int = 1,
        limit: int = 20,
    ) -> dict[str, Any]:
        db = get_database()
        admin_object_id = parse_object_id(admin_id, "admin")
        query = {"createdBy": admin_object_id, "isDeleted": False}
        skip = (page - 1) * limit
        total_events = await db.events.count_documents(query)
        cursor = (
            db.events.find(query)
            .sort("createdAt", -1)
            .skip(skip)
            .limit(limit)
        )
        items = [
            EventResponse(**document).model_dump(mode="json", by_alias=True)
            async for document in cursor
        ]
        return {
            "items": items,
            "pagination": {
                "page": page,
                "limit": limit,
                "total": total_events,
                "totalPages": (total_events + limit - 1) // limit,
            },
        }

    @staticmethod
    async def create_event(
        event_data: EventCreate,
        admin_id: str,
    ) -> dict[str, Any]:
        now = datetime.now(timezone.utc)
        AdminService._validate_event_timing(
            event_data.eventDate,
            event_data.registrationDeadline,
            now,
        )
        db = get_database()
        
        admin_obj_id = parse_object_id(admin_id, "admin")
        active_events_count = await db.events.count_documents({"createdBy": admin_obj_id, "isDeleted": False})
        if active_events_count >= 3:
            raise AppException(
                code="EVENT_LIMIT_REACHED",
                message="You have reached the maximum limit of 3 active events. Delete or archive an existing event before creating another.",
                status_code=403,
            )
            
        event = EventInDB(
            **event_data.model_dump(),
            createdBy=admin_obj_id,
        )
        if event.isPrivate:
            code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))
            event.inviteCode = f"PRV-{code}"
        
        event_document = event.model_dump(by_alias=True, exclude={"id"})
        result = await db.events.insert_one(event_document)
        created_event = await db.events.find_one({"_id": result.inserted_id})
        await invalidate_event_cache()
        return EventResponse(**created_event).model_dump(
            mode="json",
            by_alias=True,
        )

    @staticmethod
    async def update_event(
        event_id: str,
        event_data: EventUpdate,
    ) -> dict[str, Any]:
        db = get_database()
        event_object_id = parse_object_id(event_id, "event")
        current = await AdminService._get_event_or_404(event_object_id)
        now = datetime.now(timezone.utc)
        if current["eventDate"] <= now:
            raise AppException(
                code="EVENT_STARTED",
                message="An event cannot be edited after it starts",
                status_code=400,
            )

        update_data = event_data.model_dump(exclude_none=True)
        if not update_data:
            return EventResponse(**current).model_dump(
                mode="json",
                by_alias=True,
            )

        merged = {
            field: update_data.get(field, current[field])
            for field in (
                "name",
                "description",
                "category",
                "location",
                "eventDate",
                "registrationDeadline",
                "capacity",
                "categoryFields",
            )
        }
        validated = EventCreate(**merged)
        AdminService._validate_event_timing(
            validated.eventDate,
            validated.registrationDeadline,
            now,
        )
        update_data["updatedAt"] = now

        update_filter: dict[str, Any] = {
            "_id": event_object_id,
            "isDeleted": False,
            "eventDate": {"$gt": now},
        }
        if "capacity" in update_data:
            update_filter["$expr"] = {
                "$lte": ["$registeredCount", update_data["capacity"]]
            }

        updated = await db.events.find_one_and_update(
            update_filter,
            {"$set": update_data},
            return_document=ReturnDocument.AFTER,
        )
        if updated is None:
            latest = await AdminService._get_event_or_404(event_object_id)
            if update_data.get("capacity", latest["capacity"]) < latest.get(
                "registeredCount",
                0,
            ):
                raise AppException(
                    code="INVALID_CAPACITY",
                    message=(
                        "Cannot reduce capacity below current registration count"
                    ),
                    status_code=400,
                )
            raise AppException(
                code="EVENT_UPDATE_CONFLICT",
                message="The event changed while it was being updated",
                status_code=409,
            )

        await invalidate_event_cache()
        return EventResponse(**updated).model_dump(mode="json", by_alias=True)

    @staticmethod
    async def delete_event(event_id: str) -> None:
        db = get_database()
        event_object_id = parse_object_id(event_id, "event")
        result = await db.events.update_one(
            {"_id": event_object_id, "isDeleted": False},
            {
                "$set": {
                    "isDeleted": True,
                    "isRegistrationOpen": False,
                    "updatedAt": datetime.now(timezone.utc),
                }
            },
        )
        if result.matched_count == 0:
            raise AppException(
                code="EVENT_NOT_FOUND",
                message="Event not found",
                status_code=404,
            )
        await invalidate_event_cache()

    @staticmethod
    async def close_registration(event_id: str) -> None:
        db = get_database()
        event_object_id = parse_object_id(event_id, "event")
        event = await db.events.find_one_and_update(
            {"_id": event_object_id, "isDeleted": False},
            {
                "$set": {
                    "isRegistrationOpen": False,
                    "updatedAt": datetime.now(timezone.utc),
                }
            },
            return_document=ReturnDocument.AFTER,
        )
        if event is None:
            raise AppException(
                code="EVENT_NOT_FOUND",
                message="Event not found",
                status_code=404,
            )
        await invalidate_event_cache()

    @staticmethod
    async def update_registration_status(registration_id: str, new_status: str) -> dict[str, Any]:
        from pymongo import ReturnDocument
        db = get_database()
        now = datetime.now(timezone.utc)
        reg_obj_id = parse_object_id(registration_id, "registration")
        
        reg = await db.registrations.find_one({"_id": reg_obj_id})
        if not reg:
            raise AppException(code="REGISTRATION_NOT_FOUND", message="Registration not found", status_code=404)
        
        if reg.get("status") == new_status:
            return {"status": new_status}
            
        event_id = reg["eventId"]
        
        if new_status == "confirmed":
            # Atomically check capacity and increment
            updated_event = await db.events.find_one_and_update(
                {
                    "_id": event_id,
                    "$expr": {"$lt": ["$registeredCount", "$capacity"]},
                    "isDeleted": False,
                },
                {
                    "$inc": {"registeredCount": 1},
                    "$set": {"updatedAt": now},
                },
                return_document=ReturnDocument.AFTER,
            )
            if not updated_event:
                raise AppException(code="EVENT_FULL", message="Cannot confirm: Event is full or deleted", status_code=400)
                
            await db.registrations.update_one(
                {"_id": reg_obj_id},
                {"$set": {"status": "confirmed"}}
            )
        elif new_status == "rejected":
            # If it was previously confirmed, we should decrement capacity. 
            # But normally they go from pending -> rejected. Let's handle both.
            if reg.get("status") == "confirmed":
                await db.events.update_one(
                    {"_id": event_id, "registeredCount": {"$gt": 0}},
                    {"$inc": {"registeredCount": -1}, "$set": {"updatedAt": now}}
                )
            
            await db.registrations.update_one(
                {"_id": reg_obj_id},
                {"$set": {"status": "rejected"}}
            )
        
        # Broadcast the update
        import asyncio
        asyncio.create_task(manager.broadcast({"type": "REGISTRATION_UPDATE", "eventId": str(event_id)}))
            
        return {"status": new_status}

    @staticmethod
    async def checkin_attendee(event_id: str, registration_id: str) -> dict[str, Any]:
        db = get_database()
        event_obj_id = parse_object_id(event_id, "event")
        reg_obj_id = parse_object_id(registration_id, "registration")
        
        reg = await db.registrations.find_one({"_id": reg_obj_id, "eventId": event_obj_id})
        if not reg:
            raise AppException(code="REGISTRATION_NOT_FOUND", message="Registration not found for this event", status_code=404)
        
        if reg.get("status") == "attended":
            raise AppException(code="ALREADY_CHECKED_IN", message="User has already checked in", status_code=400)
            
        if reg.get("status") != "confirmed":
            raise AppException(code="INVALID_STATUS", message="Registration is not confirmed", status_code=400)
            
        await db.registrations.update_one(
            {"_id": reg_obj_id},
            {"$set": {"status": "attended", "attendedAt": datetime.now(timezone.utc)}}
        )
        
        # Broadcast the update
        import asyncio
        asyncio.create_task(manager.broadcast({"type": "REGISTRATION_UPDATE", "eventId": str(event_obj_id)}))
        
        return {"status": "attended", "message": "Successfully checked in"}

    @staticmethod
    async def get_event_registrations(
        event_id: str,
    ) -> list[dict[str, Any]]:
        db = get_database()
        event_object_id = parse_object_id(event_id, "event")
        await AdminService._get_event_or_404(event_object_id)
        pipeline = [
            {"$match": {"eventId": event_object_id}},
            {
                "$lookup": {
                    "from": "users",
                    "localField": "userId",
                    "foreignField": "_id",
                    "as": "user",
                }
            },
            {"$unwind": "$user"},
            {"$sort": {"registeredAt": -1}},
        ]
        registrations = []
        cursor = await db.registrations.aggregate(pipeline)
        async for document in cursor:
            registrations.append(
                {
                    "registrationId": str(document["_id"]),
                    "status": document["status"],
                    "registeredAt": document["registeredAt"].isoformat(),
                    "user": UserResponse(**document["user"]).model_dump(
                        mode="json",
                        by_alias=True,
                    ),
                }
            )
        return registrations

    @staticmethod
    async def export_registrations(event_id: str) -> str:
        registrations = await AdminService.get_event_registrations(event_id)
        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerow(
            [
                "Registration ID",
                "Status",
                "Registered At",
                "User Name",
                "User Email",
            ]
        )
        for registration in registrations:
            writer.writerow(
                [
                    registration["registrationId"],
                    registration["status"],
                    registration["registeredAt"],
                    AdminService._safe_csv_cell(
                        registration["user"]["name"]
                    ),
                    AdminService._safe_csv_cell(
                        registration["user"]["email"]
                    ),
                ]
            )
        return output.getvalue()

    @staticmethod
    async def get_top_events() -> list[dict[str, Any]]:
        db = get_database()
        pipeline = [
            {"$match": {"status": "confirmed"}},
            {
                "$group": {
                    "_id": "$eventId",
                    "totalRegistrations": {"$sum": 1},
                }
            },
            {"$sort": {"totalRegistrations": -1}},
            {"$limit": 5},
            {
                "$lookup": {
                    "from": "events",
                    "localField": "_id",
                    "foreignField": "_id",
                    "as": "event",
                }
            },
            {"$unwind": "$event"},
        ]
        results = []
        cursor = await db.registrations.aggregate(pipeline)
        async for document in cursor:
            results.append(
                {
                    "eventId": str(document["_id"]),
                    "totalRegistrations": document["totalRegistrations"],
                    "event": EventResponse(**document["event"]).model_dump(
                        mode="json",
                        by_alias=True,
                    ),
                }
            )
        return results

    @staticmethod
    async def get_category_wise() -> list[dict[str, Any]]:
        db = get_database()
        pipeline = [
            {"$match": {"status": "confirmed"}},
            {
                "$lookup": {
                    "from": "events",
                    "localField": "eventId",
                    "foreignField": "_id",
                    "as": "event",
                }
            },
            {"$unwind": "$event"},
            {
                "$group": {
                    "_id": "$event.category",
                    "count": {"$sum": 1},
                }
            },
            {"$sort": {"count": -1}},
        ]
        cursor = await db.registrations.aggregate(pipeline)
        return [
            {"category": document["_id"], "count": document["count"]}
            async for document in cursor
        ]

    @staticmethod
    async def get_monthly_trend() -> list[dict[str, Any]]:
        db = get_database()
        pipeline = [
            {"$match": {"status": "confirmed"}},
            {
                "$group": {
                    "_id": {
                        "$dateToString": {
                            "format": "%Y-%m",
                            "date": "$registeredAt",
                        }
                    },
                    "count": {"$sum": 1},
                }
            },
            {"$sort": {"_id": 1}},
        ]
        cursor = await db.registrations.aggregate(pipeline)
        return [
            {"month": document["_id"], "count": document["count"]}
            async for document in cursor
        ]

    @staticmethod
    async def get_analytics_summary() -> dict[str, Any]:
        db = get_database()
        
        pipeline = [{"$group": {"_id": "$status", "count": {"$sum": 1}}}]
        cursor = await db.registrations.aggregate(pipeline)
        
        status_counts = {"pending": 0, "confirmed": 0, "rejected": 0}
        total_requests = 0
        async for doc in cursor:
            status = doc.get("_id")
            count = doc.get("count", 0)
            if status in status_counts:
                status_counts[status] = count
            total_requests += count
            
        acceptance_rate = (status_counts["confirmed"] / total_requests * 100) if total_requests > 0 else 0.0

        upcoming_events = await db.events.count_documents(
            {
                "eventDate": {"$gte": datetime.now(timezone.utc)},
                "isDeleted": False,
            }
        )
        
        return {
            "totalRegistrations": status_counts["confirmed"],
            "upcomingEventsCount": upcoming_events,
            "pendingRegistrations": status_counts["pending"],
            "confirmedRegistrations": status_counts["confirmed"],
            "rejectedRegistrations": status_counts["rejected"],
            "totalRequests": total_requests,
            "acceptanceRate": round(acceptance_rate, 2),
        }

    @staticmethod
    async def _get_event_or_404(event_id):
        event = await get_database().events.find_one(
            {"_id": event_id, "isDeleted": False}
        )
        if event is None:
            raise AppException(
                code="EVENT_NOT_FOUND",
                message="Event not found",
                status_code=404,
            )
        return event

    @staticmethod
    def _validate_event_timing(
        event_date: datetime,
        registration_deadline: datetime,
        now: datetime,
    ) -> None:
        if event_date <= now:
            raise AppException(
                code="INVALID_EVENT_DATE",
                message="eventDate must be in the future",
                status_code=400,
            )
        if registration_deadline < now:
            raise AppException(
                code="INVALID_REGISTRATION_DEADLINE",
                message="registrationDeadline cannot be in the past",
                status_code=400,
            )
        if registration_deadline > event_date:
            raise AppException(
                code="INVALID_REGISTRATION_DEADLINE",
                message="registrationDeadline cannot be after eventDate",
                status_code=400,
            )

    @staticmethod
    def _safe_csv_cell(value: str) -> str:
        if value.startswith(("=", "+", "-", "@")):
            return f"'{value}"
        return value
