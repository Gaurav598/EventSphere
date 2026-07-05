from fastapi import Depends
from fastapi.security import OAuth2PasswordBearer
from bson import ObjectId
from app.core.security import decode_access_token
from app.db.mongo import get_database
from app.models.user import UserInDB
from app.exceptions.handlers import AppException

oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"/api/v1/auth/login")

async def get_current_user(token: str = Depends(oauth2_scheme)) -> UserInDB:
    payload = decode_access_token(token)
    user_id = payload.get("sub")
    if user_id is None:
        raise AppException(code="INVALID_TOKEN", message="Could not validate credentials", status_code=401)
    
    db = get_database()
    user_dict = await db.users.find_one({"_id": ObjectId(user_id)})
    if not user_dict:
        raise AppException(code="USER_NOT_FOUND", message="User not found", status_code=404)
    
    return UserInDB(**user_dict)

async def require_admin(current_user: UserInDB = Depends(get_current_user)) -> UserInDB:
    if current_user.role != "admin":
        raise AppException(code="FORBIDDEN", message="Admin privileges required", status_code=403)
    return current_user
