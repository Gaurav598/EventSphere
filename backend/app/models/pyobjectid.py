from typing import Annotated, Any
from pydantic import BeforeValidator

def check_object_id(value: Any) -> str:
    if isinstance(value, str):
        return value
    return str(value)

PyObjectId = Annotated[str, BeforeValidator(check_object_id)]
