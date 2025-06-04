from sqlalchemy import Column, String, Integer, DateTime
from database import Base

class FCMToken(Base):
    __tablename__ = "fcm_tokens"
    mobile = Column(String, primary_key=True, index=True)
    fcm_token = Column(String, unique=True)

class Message(Base):
    __tablename__ = "messages"
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    mobile = Column(String, index=True)
    message = Column(String)
    visible_upto = Column(DateTime)
    priority = Column(Integer, default=0)
