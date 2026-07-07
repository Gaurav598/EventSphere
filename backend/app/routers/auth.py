from fastapi import APIRouter, Depends

from app.dependencies.auth import get_current_user
from app.dependencies.rate_limit import RateLimiter
from app.models.user import UserCreate, UserInDB, UserLogin, UserResponse
from app.services.auth_service import AuthService
from pydantic import BaseModel
from typing import Optional

class ProfileUpdate(BaseModel):
    name: Optional[str] = None
    currentPassword: Optional[str] = None
    newPassword: Optional[str] = None

router = APIRouter()
login_rate_limiter = RateLimiter(key_prefix="login", limit=5, window=60)


@router.post("/register", status_code=201)
async def register(user_data: UserCreate):
    result = await AuthService.register_user(user_data)
    return {
        "success": True,
        "data": result,
        "message": "Registration successful",
    }


@router.post("/login", dependencies=[Depends(login_rate_limiter)])
async def login(login_data: UserLogin):
    result = await AuthService.login_user(login_data)
    return {
        "success": True,
        "data": result,
        "message": "Login successful",
    }


@router.get("/me")
async def get_me(current_user: UserInDB = Depends(get_current_user)):
    user_response = UserResponse(**current_user.model_dump(by_alias=True))
    return {
        "success": True,
        "data": user_response.model_dump(mode="json", by_alias=True),
        "message": "User profile retrieved",
    }

@router.put("/me")
async def update_profile(
    profile_data: ProfileUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    result = await AuthService.update_profile(
        user_id=str(current_user.id),
        name=profile_data.name,
        current_password=profile_data.currentPassword,
        new_password=profile_data.newPassword
    )
    return {
        "success": True,
        "data": result,
        "message": "User profile updated",
    }
