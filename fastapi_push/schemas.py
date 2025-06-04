from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class RegisterRequest(BaseModel):
    mobile: str
    fcm_token: str

class SendMessageRequest(BaseModel):
    mobile: str
    message: str
    visible_upto: Optional[datetime] = None
    priority: Optional[int] = 0

class CreateMessageRequest(BaseModel):
    mobile: str
    message: str
    visible_upto: Optional[datetime] = None
    priority: Optional[int] = 0

class MessageResponse(BaseModel):
    id: int
    message: str
    visible_upto: Optional[datetime]
    priority: int

    class Config:
        orm_mode = True
