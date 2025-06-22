from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import SessionLocal
from models import Group, Message, Contact
from sqlalchemy import func
from datetime import datetime, timedelta

from firebase_admin import messaging



router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_all_subgroup_ids(group_id: int, db: Session):
    ids = [group_id]
    stack = [group_id]
    while stack:
        curr = stack.pop()
        subs = db.query(Group).filter(Group.parent_id == curr).all()
        for sub in subs:
            ids.append(sub.id)
            stack.append(sub.id)
    return ids

@router.post("/send-message/{group_id}/")
def send_message(group_id: int, content: str, priority: str = "low", expiry_days: int = 7, db: Session = Depends(get_db)):
    all_ids = get_all_subgroup_ids(group_id, db)
    expiry_date = datetime.utcnow() + timedelta(days=expiry_days)

    fcm_tokens = set()

    # Save messages and collect tokens
    for gid in all_ids:
        message = Message(content=content, group_id=gid, priority=priority, expiry=expiry_date)
        db.add(message)

        group = db.query(Group).filter(Group.id == gid).first()
        if group:
            for contact in group.contacts:
                if contact.device_id:
                    fcm_tokens.add(contact.device_id)

    print(f"Sending message to groups: {all_ids}, with content: {content}, priority: {priority}, expiry: {expiry_date}")
    print(f"FCM Tokens collected: {fcm_tokens}")

    db.commit()

    # Send push notifications
    responses = []
    for token in fcm_tokens:
        try:
            firebase_message = messaging.Message(
                notification=messaging.Notification(
                    title="New Message",
                    body=content
                ),
                token=token
            )
            response = messaging.send(firebase_message)
            responses.append({"token": token, "status": "sent", "response": response})
        except Exception as e:
            responses.append({"token": token, "status": "failed", "error": str(e)})

    return {
        "status": "Message sent to groups",
        "group_ids": all_ids,
        "push_results": responses
    }


@router.get("/messages/history/")
def get_message_history(db: Session = Depends(get_db)):
    messages = db.query(Message).order_by(Message.timestamp.desc()).all()
    return [
        {
            "id": msg.id,
            "group": msg.group.name,
            "content": msg.content,
            "priority": msg.priority.value,
            "expiry": msg.expiry.strftime("%Y-%m-%d %H:%M"),
            "timestamp": msg.timestamp.strftime("%Y-%m-%d %H:%M")
        }
        for msg in messages
    ]

@router.get("/messages/{phone_number}/")
def get_messages_by_contact(phone_number: str, db: Session = Depends(get_db)):
    contact = db.query(Contact).filter_by(phone_number=phone_number).first()
    if not contact:
        raise HTTPException(status_code=404, detail="Contact not found")
    group_ids = [g.id for g in contact.groups]
    now = datetime.utcnow()
    messages = db.query(Message).filter(Message.group_id.in_(group_ids), Message.expiry > now).order_by(Message.timestamp.desc()).all()
    return [
        {
            "id": msg.id,
            "group": msg.group.name,
            "content": msg.content,
            "priority": msg.priority.value,
            "expiry": msg.expiry.strftime("%Y-%m-%d %H:%M"),
            "timestamp": msg.timestamp.strftime("%Y-%m-%d %H:%M")
        }
        for msg in messages
    ]

@router.delete("/messages/{message_id}/")
def delete_message(message_id: int, db: Session = Depends(get_db)):
    message = db.query(Message).filter_by(id=message_id).first()
    if not message:
        raise HTTPException(status_code=404, detail="Message not found")
    db.delete(message)
    db.commit()
    return {"status": "Message deleted"}

