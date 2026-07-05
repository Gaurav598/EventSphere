from typing import Optional
from datetime import datetime, timezone
from pydantic import BaseModel, EmailStr, Field
from app.models.pyobjectid import PyObjectId

class UserBase(BaseModel):
    name: str
    email: EmailStr
    role: str = "user" # user or admin

class UserCreate(UserBase):
    password: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserInDB(UserBase):
    id: Optional[PyObjectId] = Field(alias="_id", default=None)
    passwordHash: str
    createdAt: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    updatedAt: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

class UserResponse(UserBase):
    id: PyObjectId = Field(alias="_id")
    createdAt: datetime
    updatedAt: datetime
    
    class Config:
        populate_by_name = True
