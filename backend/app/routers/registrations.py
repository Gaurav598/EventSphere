from fastapi import APIRouter, Depends, BackgroundTasks
from app.services.registration_service import RegistrationService
from app.dependencies.auth import get_current_user
from app.dependencies.rate_limit import RateLimiter
from app.models.user import UserInDB
from app.background.ticket_generator import generate_ticket_for_registration

router = APIRouter()

# 10 attempts per 60 minutes per user for registration
registration_rate_limiter = RateLimiter(key_prefix="register", limit=10, window=3600)

@router.post("/events/{event_id}/register", dependencies=[Depends(registration_rate_limiter)])
async def register_for_event(event_id: str, background_tasks: BackgroundTasks, current_user: UserInDB = Depends(get_current_user)):
    # Create the registration
    result = await RegistrationService.register_user_for_event(str(current_user.id), event_id)
    
    # Trigger background task for QR generation
    background_tasks.add_task(generate_ticket_for_registration, result["registrationId"])
    
    return {
        "success": True,
        "data": result,
        "message": "Registration successful. Ticket is being generated."
    }

@router.get("/registrations/me")
async def get_my_registrations(current_user: UserInDB = Depends(get_current_user)):
    result = await RegistrationService.get_my_registrations(str(current_user.id))
    return {
        "success": True,
        "data": result,
        "message": "User registrations retrieved successfully"
    }

@router.get("/registrations/{registration_id}/ticket")
async def get_ticket(registration_id: str, current_user: UserInDB = Depends(get_current_user)):
    result = await RegistrationService.get_ticket(registration_id, str(current_user.id))
    return {
        "success": True,
        "data": result,
        "message": "Ticket retrieved successfully"
    }
