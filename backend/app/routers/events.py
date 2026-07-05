from fastapi import APIRouter, Query
from app.services.event_service import EventService

router = APIRouter()

@router.get("")
async def get_events(page: int = Query(1, ge=1), limit: int = Query(20, ge=1, le=100)):
    result = await EventService.get_events(page=page, limit=limit)
    return {
        "success": True,
        "data": result,
        "message": "Events retrieved successfully"
    }

@router.get("/search")
async def search_events(q: str = Query(..., min_length=1), page: int = Query(1, ge=1), limit: int = Query(20, ge=1, le=100)):
    result = await EventService.search_events(q=q, page=page, limit=limit)
    return {
        "success": True,
        "data": result,
        "message": "Events search results retrieved successfully"
    }

@router.get("/{event_id}")
async def get_event(event_id: str):
    result = await EventService.get_event(event_id)
    return {
        "success": True,
        "data": result,
        "message": "Event details retrieved successfully"
    }
