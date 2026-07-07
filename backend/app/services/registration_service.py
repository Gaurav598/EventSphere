import json
import logging
from datetime import datetime, timezone
from typing import Any

from pymongo import ReturnDocument
from pymongo.errors import DuplicateKeyError
from redis.exceptions import RedisError

from app.core.identifiers import parse_object_id
from app.db.mongo import get_database
from app.db.redis_client import get_redis, invalidate_event_cache
from app.exceptions.handlers import AppException
from app.core.websocket_manager import manager
from app.models.event import EventResponse
from app.models.registration import RegistrationInDB, RegistrationResponse
from app.models.ticket import TicketResponse

logger = logging.getLogger(__name__)


class RegistrationService:
    @staticmethod
    async def register_user_for_event(
        user_id: str,
        event_id: str,
    ) -> dict[str, Any]:
        db = get_database()
        event_object_id = parse_object_id(event_id, "event")
        user_object_id = parse_object_id(user_id, "user")
        now = datetime.now(timezone.utc)

        # Pre-fetch event to check if it's private
        event = await db.events.find_one({"_id": event_object_id, "isDeleted": False})
        if not event:
            raise AppException(code="EVENT_NOT_FOUND", message="Event not found", status_code=404)
            
        is_private = event.get("isPrivate", False)

        if is_private:
            # Private events bypass capacity checks and go to 'pending' state
            if event.get("eventDate") and event["eventDate"] <= now:
                raise AppException(code="EVENT_STARTED", message="This event has already started", status_code=400)
            if event.get("registrationDeadline") and event["registrationDeadline"] < now:
                raise AppException(code="REGISTRATION_DEADLINE_PASSED", message="The registration deadline has passed", status_code=400)
            if not event.get("isRegistrationOpen"):
                raise AppException(code="REGISTRATION_CLOSED", message="Registration is closed for this event", status_code=400)
            
            registration = RegistrationInDB(
                userId=user_object_id,
                eventId=event_object_id,
                status="pending",
            )
        else:
            # Public events atomically check capacity and increment
            updated_event = await db.events.find_one_and_update(
                {
                    "_id": event_object_id,
                    "eventDate": {"$gt": now},
                    "registrationDeadline": {"$gte": now},
                    "$expr": {"$lt": ["$registeredCount", "$capacity"]},
                    "isRegistrationOpen": True,
                    "isDeleted": False,
                },
                {
                    "$inc": {"registeredCount": 1},
                    "$set": {"updatedAt": now},
                },
                return_document=ReturnDocument.AFTER,
            )
            if updated_event is None:
                await RegistrationService._raise_registration_blocker(event_object_id, now)

            registration = RegistrationInDB(
                userId=user_object_id,
                eventId=event_object_id,
                status="confirmed",
            )

        registration_document = registration.model_dump(by_alias=True, exclude={"id"})
        try:
            result = await db.registrations.insert_one(registration_document)
        except DuplicateKeyError as exc:
            if not is_private:
                await RegistrationService._rollback_capacity(event_object_id)
            raise AppException(
                code="ALREADY_REGISTERED",
                message="User already registered for this event",
                status_code=409,
            ) from exc
        except Exception:
            if not is_private:
                await RegistrationService._rollback_capacity(event_object_id)
            raise

        await invalidate_event_cache()
        if not is_private:
            await RegistrationService._publish_registration(
                event_id=event_id,
                user_id=user_id,
                registration_id=str(result.inserted_id),
                timestamp=registration.registeredAt,
            )
            
        import asyncio
        asyncio.create_task(manager.broadcast({"type": "REGISTRATION_UPDATE", "eventId": event_id}))
            
        return {
            "registrationId": str(result.inserted_id),
            "status": registration.status,
        }

    @staticmethod
    async def _rollback_capacity(event_id) -> None:
        db = get_database()
        await db.events.update_one(
            {"_id": event_id, "registeredCount": {"$gt": 0}},
            {
                "$inc": {"registeredCount": -1},
                "$set": {"updatedAt": datetime.now(timezone.utc)},
            },
        )

    @staticmethod
    async def _raise_registration_blocker(event_id, now: datetime) -> None:
        db = get_database()
        event = await db.events.find_one({"_id": event_id})
        if event is None or event.get("isDeleted"):
            raise AppException(
                code="EVENT_NOT_FOUND",
                message="Event not found",
                status_code=404,
            )
        if event.get("eventDate") and event["eventDate"] <= now:
            raise AppException(
                code="EVENT_STARTED",
                message="This event has already started",
                status_code=400,
            )
        if event.get("registrationDeadline") and event["registrationDeadline"] < now:
            raise AppException(
                code="REGISTRATION_DEADLINE_PASSED",
                message="The registration deadline has passed",
                status_code=400,
            )
        if not event.get("isRegistrationOpen"):
            raise AppException(
                code="REGISTRATION_CLOSED",
                message="Registration is closed for this event",
                status_code=400,
            )
        if event.get("registeredCount", 0) >= event.get("capacity", 0):
            raise AppException(
                code="EVENT_FULL",
                message="This event has reached full capacity",
                status_code=400,
            )
        raise AppException(
            code="REGISTRATION_UNAVAILABLE",
            message="Registration is currently unavailable",
            status_code=409,
        )

    @staticmethod
    async def _publish_registration(
        event_id: str,
        user_id: str,
        registration_id: str,
        timestamp: datetime,
    ) -> None:
        redis = get_redis()
        if redis is None:
            return
        message = {
            "eventId": event_id,
            "userId": user_id,
            "registrationId": registration_id,
            "timestamp": timestamp.isoformat(),
        }
        try:
            await redis.publish("registration.created", json.dumps(message))
        except RedisError:
            logger.warning(
                "Failed to publish registration event to Redis",
                exc_info=True,
            )

    @staticmethod
    async def get_my_registrations(user_id: str) -> list[dict[str, Any]]:
        db = get_database()
        user_object_id = parse_object_id(user_id, "user")
        cursor = db.registrations.find({"userId": user_object_id}).sort(
            "registeredAt",
            -1,
        )
        registration_documents = [document async for document in cursor]
        event_ids = list(
            {document["eventId"] for document in registration_documents}
        )
        event_cursor = db.events.find({"_id": {"$in": event_ids}})
        events = {
            document["_id"]: EventResponse(**document).model_dump(
                mode="json",
                by_alias=True,
            )
            async for document in event_cursor
        }

        registrations = []
        for document in registration_documents:
            item = RegistrationResponse(**document).model_dump(
                mode="json",
                by_alias=True,
            )
            item["event"] = events.get(document["eventId"])
            registrations.append(item)
        return registrations

    @staticmethod
    async def get_ticket(
        registration_id: str,
        user_id: str,
    ) -> dict[str, Any]:
        db = get_database()
        registration_object_id = parse_object_id(registration_id, "registration")
        user_object_id = parse_object_id(user_id, "user")

        registration = await db.registrations.find_one(
            {
                "_id": registration_object_id,
                "userId": user_object_id,
            }
        )
        if registration is None:
            raise AppException(
                code="REGISTRATION_NOT_FOUND",
                message="Registration not found",
                status_code=404,
            )

        ticket = await db.tickets.find_one(
            {"registrationId": registration_object_id}
        )
        if ticket is None:
            raise AppException(
                code="TICKET_NOT_READY",
                message="Ticket is still being generated. Please try again shortly.",
                status_code=409,
            )
        return TicketResponse(**ticket).model_dump(mode="json", by_alias=True)
