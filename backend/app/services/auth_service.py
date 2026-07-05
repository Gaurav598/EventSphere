from typing import Dict, Any
from app.db.mongo import get_database
from app.models.user import UserCreate, UserLogin, UserInDB, UserResponse
from app.core.security import get_password_hash, verify_password, create_access_token
from app.exceptions.handlers import AppException

class AuthService:
    @staticmethod
    async def register_user(user_data: UserCreate) -> Dict[str, Any]:
        db = get_database()
        
        # Check if email exists
        existing_user = await db.users.find_one({"email": user_data.email})
        if existing_user:
            raise AppException(code="EMAIL_IN_USE", message="Email is already registered", status_code=409)
        
        # Create user
        hashed_pw = get_password_hash(user_data.password)
        new_user = UserInDB(
            name=user_data.name,
            email=user_data.email,
            role=user_data.role,
            passwordHash=hashed_pw
        )
        
        user_dict = new_user.model_dump(by_alias=True, exclude={"id"})
        result = await db.users.insert_one(user_dict)
        
        # Get created user
        created_user = await db.users.find_one({"_id": result.inserted_id})
        return UserResponse(**created_user).model_dump(by_alias=True)

    @staticmethod
    async def login_user(login_data: UserLogin) -> Dict[str, str]:
        db = get_database()
        
        user = await db.users.find_one({"email": login_data.email})
        if not user or not verify_password(login_data.password, user["passwordHash"]):
            raise AppException(code="INVALID_CREDENTIALS", message="Invalid email or password", status_code=401)
        
        access_token = create_access_token(subject=str(user["_id"]), role=user.get("role", "user"))
        return {
            "accessToken": access_token,
            "tokenType": "bearer"
        }
