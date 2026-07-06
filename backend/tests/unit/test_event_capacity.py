from datetime import datetime, timedelta, timezone

import pytest
from bson import ObjectId

from app.db.mongo import get_database
from app.exceptions.handlers import AppException
from app.services.registration_service import RegistrationService


@pytest.mark.asyncio
async def test_event_capacity_logic():
    db = get_database()
    event_id = ObjectId()
    user_id_1 = ObjectId()
    user_id_2 = ObjectId()
    now = datetime.now(timezone.utc)
    await db.events.insert_one(
        {
            "_id": event_id,
            "name": "Small Event",
            "capacity": 1,
            "registeredCount": 0,
            "isRegistrationOpen": True,
            "isDeleted": False,
            "eventDate": now + timedelta(days=2),
            "registrationDeadline": now + timedelta(days=1),
        }
    )

    result = await RegistrationService.register_user_for_event(
        str(user_id_1),
        str(event_id),
    )
    assert result["status"] == "confirmed"
    event = await db.events.find_one({"_id": event_id})
    assert event["registeredCount"] == 1

    with pytest.raises(AppException) as exc_info:
        await RegistrationService.register_user_for_event(
            str(user_id_2),
            str(event_id),
        )
    assert exc_info.value.code == "EVENT_FULL"


@pytest.mark.asyncio
async def test_duplicate_registration_rolls_back_capacity():
    db = get_database()
    event_id = ObjectId()
    user_id = ObjectId()
    now = datetime.now(timezone.utc)
    await db.events.insert_one(
        {
            "_id": event_id,
            "capacity": 5,
            "registeredCount": 0,
            "isRegistrationOpen": True,
            "isDeleted": False,
            "eventDate": now + timedelta(days=2),
            "registrationDeadline": now + timedelta(days=1),
        }
    )
    await RegistrationService.register_user_for_event(
        str(user_id),
        str(event_id),
    )

    with pytest.raises(AppException) as exc_info:
        await RegistrationService.register_user_for_event(
            str(user_id),
            str(event_id),
        )
    assert exc_info.value.code == "ALREADY_REGISTERED"
    event = await db.events.find_one({"_id": event_id})
    assert event["registeredCount"] == 1
