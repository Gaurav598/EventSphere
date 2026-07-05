from typing import Optional
from datetime import datetime, timezone
from pydantic import BaseModel, Field
from app.models.pyobjectid import PyObjectId

class TicketBase(BaseModel):
    registrationId: PyObjectId
    qrPayload: str
    qrImageRef: str
    isValid: bool = True

class TicketInDB(TicketBase):
    id: Optional[PyObjectId] = Field(alias="_id", default=None)
    generatedAt: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

class TicketResponse(TicketInDB):
    id: PyObjectId = Field(alias="_id")
    
    class Config:
        populate_by_name = True
