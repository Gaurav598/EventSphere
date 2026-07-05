from typing import Optional, Dict, Any
from datetime import datetime, timezone
from pydantic import BaseModel, Field
from app.models.pyobjectid import PyObjectId

class EventBase(BaseModel):
    name: str
    description: str
    category: str
    location: str
    eventDate: datetime
    registrationDeadline: datetime
    capacity: int
    categoryFields: Optional[Dict[str, Any]] = {}

class EventCreate(EventBase):
    pass

class EventUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    category: Optional[str] = None
    location: Optional[str] = None
    eventDate: Optional[datetime] = None
    registrationDeadline: Optional[datetime] = None
    capacity: Optional[int] = None
    categoryFields: Optional[Dict[str, Any]] = None

class EventInDB(EventBase):
    id: Optional[PyObjectId] = Field(alias="_id", default=None)
    registeredCount: int = 0
    isRegistrationOpen: bool = True
    isDeleted: bool = False
    createdBy: PyObjectId
    createdAt: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    updatedAt: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

class EventResponse(EventBase):
    id: PyObjectId = Field(alias="_id")
    registeredCount: int
    isRegistrationOpen: bool
    createdBy: PyObjectId
    createdAt: datetime
    updatedAt: datetime

    class Config:
        populate_by_name = True
