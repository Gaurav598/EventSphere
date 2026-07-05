import json
import logging
from typing import Dict, Any, List
from bson import ObjectId
from pymongo import ReturnDocument
from app.db.mongo import get_database
from app.db.redis_client import get_redis
from app.models.registration import RegistrationInDB, RegistrationResponse
from app.models.ticket import TicketResponse
from app.exceptions.handlers import AppException

logger = logging.getLogger(__name__)

class RegistrationService:
    @staticmethod
    async def register_user_for_event(user_id: str, event_id: str) -> Dict[str, Any]:
        db = get_database()
        
        try:
            event_obj_id = ObjectId(event_id)
            user_obj_id = ObjectId(user_id)
        except Exception:
            raise AppException(code="INVALID_ID", message="Invalid ID format", status_code=400)
            
        # Check if already registered
        existing = await db.registrations.find_one({"userId": user_obj_id, "eventId": event_obj_id})
        if existing:
            raise AppException(code="ALREADY_REGISTERED", message="User already registered for this event", status_code=409)
            
        # Atomic capacity check and increment
        # find_one_and_update with condition: registeredCount < capacity and isRegistrationOpen == True
        event = await db.events.find_one_and_update(
            {
                "_id": event_obj_id,
                "$expr": {"$lt": ["$registeredCount", "$capacity"]},
                "isRegistrationOpen": True,
                "isDeleted": False
            },
            {"$inc": {"registeredCount": 1}},
            return_document=ReturnDocument.AFTER
        )
        
        if not event:
            # Check why it failed
            check_event = await db.events.find_one({"_id": event_obj_id})
            if not check_event or check_event.get("isDeleted"):
                raise AppException(code="EVENT_NOT_FOUND", message="Event not found", status_code=404)
            if not check_event.get("isRegistrationOpen"):
                raise AppException(code="REGISTRATION_CLOSED", message="Registration is closed for this event", status_code=400)
            if check_event.get("registeredCount", 0) >= check_event.get("capacity", 0):
                raise AppException(code="EVENT_FULL", message="This event has reached full capacity", status_code=400)
                
        # Create registration
        new_registration = RegistrationInDB(
            userId=user_obj_id,
            eventId=event_obj_id,
        )
        
        reg_dict = new_registration.model_dump(by_alias=True, exclude={"id"})
        result = await db.registrations.insert_one(reg_dict)
        
        # Publish to Redis Pub/Sub
        try:
            redis = get_redis()
            pubsub_message = {
                "eventId": event_id,
                "userId": user_id,
                "registrationId": str(result.inserted_id),
                "timestamp": new_registration.registeredAt.isoformat()
            }
            await redis.publish("registration.created", json.dumps(pubsub_message))
        except Exception as e:
            logger.warning(f"Failed to publish registration event to Redis: {e}")
            
        # Clear events list cache
        try:
            redis = get_redis()
            # In a real app we might delete keys matching a pattern, here we can clear specific or rely on TTL
            # For simplicity, we just rely on TTL or we could use Redis SCAN to delete all events:list keys
            # To be safe, we just let TTL expire for the list
        except Exception:
            pass

        return {"registrationId": str(result.inserted_id), "status": "confirmed"}

    @staticmethod
    async def get_my_registrations(user_id: str) -> List[Dict[str, Any]]:
        db = get_database()
        
        try:
            user_obj_id = ObjectId(user_id)
        except Exception:
            raise AppException(code="INVALID_ID", message="Invalid ID format", status_code=400)
            
        # We can do an aggregation to fetch event details as well
        pipeline = [
            {"$match": {"userId": user_obj_id}},
            {"$lookup": {
                "from": "events",
                "localField": "eventId",
                "foreignField": "_id",
                "as": "event"
            }},
            {"$unwind": "$event"},
            {"$sort": {"registeredAt": -1}}
        ]
        
        cursor = db.registrations.aggregate(pipeline)
        registrations = []
        async for doc in cursor:
            # We construct a custom response combining registration and event basic info
            item = RegistrationResponse(**doc).model_dump(mode='json', by_alias=True)
            event_data = doc.get("event", {})
            event_data["_id"] = str(event_data.get("_id"))
            if "createdBy" in event_data:
                event_data["createdBy"] = str(event_data["createdBy"])
            item["event"] = event_data
            # Just ensure eventDates are stringified
            if isinstance(item["event"].get("eventDate"), str) == False and item["event"].get("eventDate") is not None:
                item["event"]["eventDate"] = item["event"]["eventDate"].isoformat()
            if isinstance(item["event"].get("registrationDeadline"), str) == False and item["event"].get("registrationDeadline") is not None:
                 item["event"]["registrationDeadline"] = item["event"]["registrationDeadline"].isoformat()
            if isinstance(item["event"].get("createdAt"), str) == False and item["event"].get("createdAt") is not None:
                 item["event"]["createdAt"] = item["event"]["createdAt"].isoformat()
            if isinstance(item["event"].get("updatedAt"), str) == False and item["event"].get("updatedAt") is not None:
                 item["event"]["updatedAt"] = item["event"]["updatedAt"].isoformat()
            registrations.append(item)
            
        return registrations

    @staticmethod
    async def get_ticket(registration_id: str, user_id: str) -> Dict[str, Any]:
        db = get_database()
        
        try:
            reg_obj_id = ObjectId(registration_id)
            user_obj_id = ObjectId(user_id)
        except Exception:
            raise AppException(code="INVALID_ID", message="Invalid ID format", status_code=400)
            
        # Ensure the registration belongs to the user
        registration = await db.registrations.find_one({"_id": reg_obj_id, "userId": user_obj_id})
        if not registration:
            raise AppException(code="NOT_FOUND", message="Registration not found", status_code=404)
            
        ticket = await db.tickets.find_one({"registrationId": reg_obj_id})
        if not ticket:
            raise AppException(code="TICKET_NOT_READY", message="Ticket is still being generated. Please try again later.", status_code=404)
            
        return TicketResponse(**ticket).model_dump(mode='json', by_alias=True)
