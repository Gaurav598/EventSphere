from datetime import datetime

from fastapi import APIRouter, Query

from app.exceptions.handlers import AppException
from app.services.event_service import EventService

router = APIRouter()


def _validate_filter_dates(
    date_from: datetime | None,
    date_to: datetime | None,
) -> None:
    for value in (date_from, date_to):
        if value is not None and (
            value.tzinfo is None or value.utcoffset() is None
        ):
            raise AppException(
                code="INVALID_DATE_FILTER",
                message="Date filters must include a timezone",
                status_code=400,
            )
    if date_from is not None and date_to is not None and date_from > date_to:
        raise AppException(
            code="INVALID_DATE_RANGE",
            message="date_from cannot be after date_to",
            status_code=400,
        )


@router.get("")
async def get_events(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    category: str | None = Query(default=None, min_length=1, max_length=50),
    location: str | None = Query(default=None, min_length=1, max_length=250),
    date_from: datetime | None = None,
    date_to: datetime | None = None,
    available_only: bool = False,
):
    _validate_filter_dates(date_from, date_to)
    result = await EventService.get_events(
        page=page,
        limit=limit,
        category=category,
        location=location,
        date_from=date_from,
        date_to=date_to,
        available_only=available_only,
    )
    return {
        "success": True,
        "data": result["items"],
        "pagination": result["pagination"],
        "message": "Events retrieved successfully",
    }


@router.get("/search")
async def search_events(
    q: str = Query(..., min_length=1, max_length=100),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    date_from: datetime | None = None,
    date_to: datetime | None = None,
    available_only: bool = False,
):
    _validate_filter_dates(date_from, date_to)
    result = await EventService.search_events(
        q=q,
        page=page,
        limit=limit,
        date_from=date_from,
        date_to=date_to,
        available_only=available_only,
    )
    return {
        "success": True,
        "data": result["items"],
        "pagination": result["pagination"],
        "message": "Events search results retrieved successfully",
    }


@router.get("/{event_id}")
async def get_event(event_id: str):
    result = await EventService.get_event(event_id)
    return {
        "success": True,
        "data": result,
        "message": "Event details retrieved successfully",
    }
