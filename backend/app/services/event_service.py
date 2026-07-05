import json
import hashlib
from typing import List, Dict, Any, Optional
from bson import ObjectId
from app.db.mongo import get_database
from app.db.redis_client import get_redis
from app.models.event import EventResponse
from app.exceptions.handlers import AppException

class EventService:
    @staticmethod
    async def get_events(page: int = 1, limit: int = 20) -> Dict[str, Any]:
        redis = get_redis()
        cache_key = f"events:list:page:{page}:limit:{limit}"
        
        # Check cache
        try:
            cached_data = await redis.get(cache_key)
            if cached_data:
                return json.loads(cached_data)
        except Exception as e:
            import logging
            logging.getLogger(__name__).warning(f"Redis cache read failed: {e}")
            
        db = get_database()
        skip = (page - 1) * limit
        
        # Query active and upcoming events
        query = {"isDeleted": False}
        total_events = await db.events.count_documents(query)
        cursor = db.events.find(query).sort("eventDate", 1).skip(skip).limit(limit)
        
        events = []
        async for doc in cursor:
            events.append(EventResponse(**doc).model_dump(by_alias=True))
            
        # Serialize datetime objects using a custom encoder or convert them earlier
        # EventResponse.model_dump handles the conversion if properly configured, but let's ensure JSON serializability
        # model_dump(mode='json') handles datetime
        events_json = []
        cursor = db.events.find(query).sort("eventDate", 1).skip(skip).limit(limit)
        async for doc in cursor:
            events_json.append(EventResponse(**doc).model_dump(mode='json', by_alias=True))
            
        result = {
            "events": events_json,
            "pagination": {
                "page": page,
                "limit": limit,
                "total": total_events,
                "totalPages": (total_events + limit - 1) // limit
            }
        }
        
        # Set cache
        try:
            await redis.setex(cache_key, 300, json.dumps(result))
        except Exception as e:
            import logging
            logging.getLogger(__name__).warning(f"Redis cache write failed: {e}")
            
        return result

    @staticmethod
    async def get_event(event_id: str) -> Dict[str, Any]:
        db = get_database()
        try:
            obj_id = ObjectId(event_id)
        except Exception:
            raise AppException(code="INVALID_ID", message="Invalid event ID format", status_code=400)
            
        event = await db.events.find_one({"_id": obj_id, "isDeleted": False})
        if not event:
            raise AppException(code="EVENT_NOT_FOUND", message="Event not found", status_code=404)
            
        return EventResponse(**event).model_dump(mode='json', by_alias=True)

    @staticmethod
    async def search_events(q: str, page: int = 1, limit: int = 20) -> Dict[str, Any]:
        db = get_database()
        skip = (page - 1) * limit
        
        # Create text index if not exists (in a real app, do this on startup/migration)
        # Assuming index exists. Simple regex search as fallback if text index is missing.
        query = {
            "isDeleted": False,
            "$or": [
                {"name": {"$regex": q, "$options": "i"}},
                {"category": {"$regex": q, "$options": "i"}},
                {"location": {"$regex": q, "$options": "i"}}
            ]
        }
        
        total_events = await db.events.count_documents(query)
        cursor = db.events.find(query).sort("eventDate", 1).skip(skip).limit(limit)
        
        events_json = []
        async for doc in cursor:
            events_json.append(EventResponse(**doc).model_dump(mode='json', by_alias=True))
            
        return {
            "events": events_json,
            "pagination": {
                "page": page,
                "limit": limit,
                "total": total_events,
                "totalPages": (total_events + limit - 1) // limit
            }
        }
