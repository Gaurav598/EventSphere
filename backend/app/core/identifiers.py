from bson import ObjectId
from bson.errors import InvalidId

from app.exceptions.handlers import AppException


def parse_object_id(value: str, resource: str = "resource") -> ObjectId:
    try:
        return ObjectId(value)
    except (InvalidId, TypeError) as exc:
        raise AppException(
            code="INVALID_ID",
            message=f"Invalid {resource} ID",
            status_code=400,
        ) from exc
