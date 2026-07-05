import pytest
from bson import ObjectId
from app.db.mongo import get_database
from app.services.registration_service import RegistrationService
from app.exceptions.handlers import AppException

@pytest.mark.asyncio
async def test_event_capacity_logic():
    db = get_database()
    
    event_id = ObjectId()
    user_id_1 = ObjectId()
    user_id_2 = ObjectId()
    
    # Create an event with capacity 1
    await db.events.insert_one({
        "_id": event_id,
        "name": "Small Event",
        "capacity": 1,
        "registeredCount": 0,
        "isRegistrationOpen": True,
        "isDeleted": False,
    })
    
    # Register first user (should succeed)
    result = await RegistrationService.register_user_for_event(str(user_id_1), str(event_id))
    assert result["status"] == "confirmed"
    
    # Check updated event
    event = await db.events.find_one({"_id": event_id})
    assert event["registeredCount"] == 1
    
    # Register second user (should fail due to capacity)
    with pytest.raises(AppException) as excinfo:
        await RegistrationService.register_user_for_event(str(user_id_2), str(event_id))
        
    assert excinfo.value.code == "EVENT_FULL"
    assert excinfo.value.status_code == 400
