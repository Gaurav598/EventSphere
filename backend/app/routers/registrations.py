from fastapi import APIRouter, BackgroundTasks, Depends

from app.background.ticket_generator import generate_ticket_for_registration
from app.dependencies.auth import get_current_user
from app.dependencies.rate_limit import RateLimiter
from app.models.user import UserInDB
from app.services.registration_service import RegistrationService

router = APIRouter()
registration_rate_limiter = RateLimiter(
    key_prefix="register",
    limit=10,
    window=3600,
)


@router.post("/events/{event_id}/register", status_code=201)
async def register_for_event(
    event_id: str,
    background_tasks: BackgroundTasks,
    current_user: UserInDB = Depends(get_current_user),
):
    await registration_rate_limiter.check(str(current_user.id))
    result = await RegistrationService.register_user_for_event(
        str(current_user.id),
        event_id,
    )
    background_tasks.add_task(
        generate_ticket_for_registration,
        result["registrationId"],
    )
    return {
        "success": True,
        "data": result,
        "message": "Registration successful. Ticket is being generated.",
    }


@router.get("/registrations/me")
async def get_my_registrations(
    current_user: UserInDB = Depends(get_current_user),
):
    result = await RegistrationService.get_my_registrations(str(current_user.id))
    return {
        "success": True,
        "data": result,
        "message": "User registrations retrieved successfully",
    }


@router.get("/registrations/{registration_id}/ticket")
async def get_ticket(
    registration_id: str,
    current_user: UserInDB = Depends(get_current_user),
):
    result = await RegistrationService.get_ticket(
        registration_id,
        str(current_user.id),
    )
    return {
        "success": True,
        "data": result,
        "message": "Ticket retrieved successfully",
    }
