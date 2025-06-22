from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, Table, Enum
from sqlalchemy.orm import relationship
from datetime import datetime, timedelta
from database import Base
import enum

class PriorityEnum(enum.Enum):
    low = "low"
    medium = "medium"
    high = "high"

# Association Table for Many-to-Many between Contacts and Groups
contact_groups = Table(
    "contact_groups",
    Base.metadata,
    Column("contact_id", Integer, ForeignKey("contacts.id"), primary_key=True),
    Column("group_id", Integer, ForeignKey("groups.id"), primary_key=True)
)

class Group(Base):
    __tablename__ = "groups"
    id = Column(Integer, primary_key=True)
    name = Column(String(255), nullable=False)
    parent_id = Column(Integer, ForeignKey("groups.id"), nullable=True)
    children = relationship("Group")
    contacts = relationship("Contact", secondary=contact_groups, back_populates="groups")
    messages = relationship("Message", back_populates="group")

class Contact(Base):
    __tablename__ = "contacts"
    id = Column(Integer, primary_key=True)
    name = Column(String(255))
    phone_number = Column(String(20), unique=True)
    device_id = Column(String(255), nullable=True)
    groups = relationship("Group", secondary=contact_groups, back_populates="contacts")

class Message(Base):
    __tablename__ = "messages"
    id = Column(Integer, primary_key=True)
    content = Column(Text, nullable=False)
    timestamp = Column(DateTime, default=datetime.utcnow)
    expiry = Column(DateTime, default=lambda: datetime.utcnow() + timedelta(days=7))
    priority = Column(Enum(PriorityEnum), default=PriorityEnum.low)
    group_id = Column(Integer, ForeignKey("groups.id"))
    group = relationship("Group", back_populates="messages")
