from fastapi import Depends
from fastapi.security import OAuth2PasswordBearer

from app.core.identifiers import parse_object_id
from app.core.security import decode_access_token
from app.db.mongo import get_database
from app.exceptions.handlers import AppException
from app.models.user import UserInDB

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


async def get_current_user(token: str = Depends(oauth2_scheme)) -> UserInDB:
    payload = decode_access_token(token)
    user_id = payload.get("sub")
    if not isinstance(user_id, str):
        raise AppException(
            code="INVALID_TOKEN",
            message="Could not validate credentials",
            status_code=401,
        )

    try:
        object_id = parse_object_id(user_id, "user")
    except AppException as exc:
        raise AppException(
            code="INVALID_TOKEN",
            message="Could not validate credentials",
            status_code=401,
        ) from exc

    db = get_database()
    user_dict = await db.users.find_one({"_id": object_id})
    if not user_dict:
        raise AppException(
            code="INVALID_TOKEN",
            message="Could not validate credentials",
            status_code=401,
        )

    return UserInDB(**user_dict)


async def require_admin(current_user: UserInDB = Depends(get_current_user)) -> UserInDB:
    if current_user.role != "admin":
        raise AppException(
            code="FORBIDDEN",
            message="Admin privileges required",
            status_code=403,
        )
    return current_user
