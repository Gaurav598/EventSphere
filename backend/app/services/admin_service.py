import csv
import io
from typing import Dict, Any, List
from datetime import datetime, timezone
from bson import ObjectId
from app.db.mongo import get_database
from app.db.redis_client import get_redis
from app.models.event import EventCreate, EventUpdate, EventInDB, EventResponse
from app.models.user import UserResponse
from app.exceptions.handlers import AppException

class AdminService:
    @staticmethod
    async def create_event(event_data: EventCreate, admin_id: str) -> Dict[str, Any]:
        db = get_database()
        
        new_event = EventInDB(
            **event_data.model_dump(),
            createdBy=ObjectId(admin_id)
        )
        
        event_dict = new_event.model_dump(by_alias=True, exclude={"id"})
        result = await db.events.insert_one(event_dict)
        
        created_event = await db.events.find_one({"_id": result.inserted_id})
        
        # Clear redis cache
        redis = get_redis()
        # simplified cache clearing, ideally use SCAN to clear pattern
        # for now let's just rely on TTL as specified in docs (acceptable staleness)
        
        return EventResponse(**created_event).model_dump(mode='json', by_alias=True)

    @staticmethod
    async def update_event(event_id: str, event_data: EventUpdate) -> Dict[str, Any]:
        db = get_database()
        try:
            obj_id = ObjectId(event_id)
        except Exception:
            raise AppException(code="INVALID_ID", message="Invalid event ID", status_code=400)
            
        current_event = await db.events.find_one({"_id": obj_id, "isDeleted": False})
        if not current_event:
            raise AppException(code="EVENT_NOT_FOUND", message="Event not found", status_code=404)
            
        update_data = {k: v for k, v in event_data.model_dump().items() if v is not None}
        if "capacity" in update_data:
            if update_data["capacity"] < current_event.get("registeredCount", 0):
                raise AppException(code="INVALID_CAPACITY", message="Cannot reduce capacity below current registration count", status_code=400)
                
        update_data["updatedAt"] = datetime.now(timezone.utc)
        
        await db.events.update_one({"_id": obj_id}, {"$set": update_data})
        updated_event = await db.events.find_one({"_id": obj_id})
        
        return EventResponse(**updated_event).model_dump(mode='json', by_alias=True)

    @staticmethod
    async def delete_event(event_id: str) -> bool:
        db = get_database()
        try:
            obj_id = ObjectId(event_id)
        except Exception:
            raise AppException(code="INVALID_ID", message="Invalid event ID", status_code=400)
            
        result = await db.events.update_one(
            {"_id": obj_id}, 
            {"$set": {"isDeleted": True, "updatedAt": datetime.now(timezone.utc)}}
        )
        
        if result.modified_count == 0:
            raise AppException(code="EVENT_NOT_FOUND", message="Event not found", status_code=404)
            
        return True

    @staticmethod
    async def close_registration(event_id: str) -> bool:
        db = get_database()
        try:
            obj_id = ObjectId(event_id)
        except Exception:
            raise AppException(code="INVALID_ID", message="Invalid event ID", status_code=400)
            
        result = await db.events.update_one(
            {"_id": obj_id, "isDeleted": False}, 
            {"$set": {"isRegistrationOpen": False, "updatedAt": datetime.now(timezone.utc)}}
        )
        
        if result.modified_count == 0:
            raise AppException(code="EVENT_NOT_FOUND", message="Event not found", status_code=404)
            
        return True

    @staticmethod
    async def get_event_registrations(event_id: str) -> List[Dict[str, Any]]:
        db = get_database()
        try:
            obj_id = ObjectId(event_id)
        except Exception:
            raise AppException(code="INVALID_ID", message="Invalid event ID", status_code=400)
            
        pipeline = [
            {"$match": {"eventId": obj_id}},
            {"$lookup": {
                "from": "users",
                "localField": "userId",
                "foreignField": "_id",
                "as": "user"
            }},
            {"$unwind": "$user"}
        ]
        
        cursor = db.registrations.aggregate(pipeline)
        results = []
        async for doc in cursor:
            user_data = UserResponse(**doc["user"]).model_dump(mode='json', by_alias=True)
            results.append({
                "registrationId": str(doc["_id"]),
                "status": doc.get("status"),
                "registeredAt": doc.get("registeredAt").isoformat() if doc.get("registeredAt") else None,
                "user": user_data
            })
            
        return results

    @staticmethod
    async def export_registrations(event_id: str) -> str:
        registrations = await AdminService.get_event_registrations(event_id)
        
        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerow(["Registration ID", "Status", "Registered At", "User Name", "User Email"])
        
        for reg in registrations:
            writer.writerow([
                reg["registrationId"],
                reg["status"],
                reg["registeredAt"],
                reg["user"]["name"],
                reg["user"]["email"]
            ])
            
        return output.getvalue()

    @staticmethod
    async def get_top_events() -> List[Dict[str, Any]]:
        db = get_database()
        pipeline = [
            {"$group": {"_id": "$eventId", "totalRegistrations": {"$sum": 1}}},
            {"$sort": {"totalRegistrations": -1}},
            {"$limit": 5},
            {"$lookup": {
                "from": "events",
                "localField": "_id",
                "foreignField": "_id",
                "as": "event"
            }},
            {"$unwind": "$event"}
        ]
        
        cursor = db.registrations.aggregate(pipeline)
        results = []
        async for doc in cursor:
            event_data = EventResponse(**doc["event"]).model_dump(mode='json', by_alias=True)
            results.append({
                "eventId": str(doc["_id"]),
                "totalRegistrations": doc["totalRegistrations"],
                "event": event_data
            })
        return results

    @staticmethod
    async def get_category_wise() -> List[Dict[str, Any]]:
        db = get_database()
        pipeline = [
            {"$lookup": {"from": "events", "localField": "eventId", "foreignField": "_id", "as": "event"}},
            {"$unwind": "$event"},
            {"$group": {"_id": "$event.category", "count": {"$sum": 1}}}
        ]
        
        cursor = db.registrations.aggregate(pipeline)
        results = []
        async for doc in cursor:
            results.append({
                "category": doc["_id"],
                "count": doc["count"]
            })
        return results

    @staticmethod
    async def get_monthly_trend() -> List[Dict[str, Any]]:
        db = get_database()
        pipeline = [
            {"$group": {
                "_id": {"$dateToString": {"format": "%Y-%m", "date": "$registeredAt"}},
                "count": {"$sum": 1}
            }},
            {"$sort": {"_id": 1}}
        ]
        
        cursor = db.registrations.aggregate(pipeline)
        results = []
        async for doc in cursor:
            results.append({
                "month": doc["_id"],
                "count": doc["count"]
            })
        return results

    @staticmethod
    async def get_analytics_summary() -> Dict[str, Any]:
        db = get_database()
        
        total_registrations = await db.registrations.count_documents({})
        upcoming_events = await db.events.count_documents({
            "eventDate": {"$gte": datetime.now(timezone.utc)},
            "isDeleted": False
        })
        
        return {
            "totalRegistrations": total_registrations,
            "upcomingEventsCount": upcoming_events
        }
