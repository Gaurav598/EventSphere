from typing import Optional
from datetime import datetime, timezone
from pydantic import BaseModel, Field
from app.models.pyobjectid import PyObjectId

class RegistrationBase(BaseModel):
    userId: PyObjectId
    eventId: PyObjectId
    status: str = "confirmed"

class RegistrationInDB(RegistrationBase):
    id: Optional[PyObjectId] = Field(alias="_id", default=None)
    registeredAt: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

class RegistrationResponse(RegistrationInDB):
    id: PyObjectId = Field(alias="_id")
    
    class Config:
        populate_by_name = True
