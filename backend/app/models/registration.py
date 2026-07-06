from datetime import datetime, timezone
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

from app.models.pyobjectid import PyObjectId


class RegistrationBase(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    userId: PyObjectId
    eventId: PyObjectId
    status: Literal["pending", "confirmed", "cancelled", "rejected"] = "confirmed"


class RegistrationInDB(RegistrationBase):
    id: PyObjectId | None = Field(alias="_id", default=None)
    registeredAt: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


class RegistrationResponse(RegistrationInDB):
    id: PyObjectId = Field(alias="_id")
