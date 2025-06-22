from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import SessionLocal
from models import Group, Message, Contact
from sqlalchemy import func
from datetime import datetime, timedelta, timezone

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

def get_all_parent_group_ids(group_id: int, db: Session):
    """Recursively collect all parent group IDs for a given group, including itself."""
    ids = [group_id]
    current = db.query(Group).filter(Group.id == group_id).first()
    while current and current.parent_id:
        ids.append(current.parent_id)
        current = db.query(Group).filter(Group.id == current.parent_id).first()
    return ids

@router.post("/send-message/{group_id}/")
def send_message(group_id: int, content: str, priority: str = "low", expiry_days: int = 7, db: Session = Depends(get_db)):
    all_ids = get_all_subgroup_ids(group_id, db)
    expiry_date = datetime.utcnow() + timedelta(days=expiry_days)
    message = Message(content=content, group_id=group_id, priority=priority, expiry=expiry_date)
    db.add(message)

    fcm_tokens = set()

    # Save messages and collect tokens
    for gid in all_ids:
        group = db.query(Group).filter(Group.id == gid).first()
        if group:
            for contact in group.contacts:
                print(f"Contact {contact.name} with phone {contact.phone_number} in group {group.name}")
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
    unique_messages = {}
    for msg in messages:
        key = msg.id  # or (msg.content, msg.priority, msg.expiry) for stricter uniqueness
        if key not in unique_messages or msg.group_id < unique_messages[key].group_id:
            unique_messages[key] = msg
    messages = list(unique_messages.values())
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

    # Collect all parent groups (i.e., college → user’s group)
    group_ids = set()
    for g in contact.groups:
        group_ids.update(get_all_parent_group_ids(g.id, db))  # ← correct usage here

    now = datetime.now(timezone.utc)

    # Fetch messages from only the relevant groups (user’s group and its ancestors)
    messages = db.query(Message).filter(
        Message.group_id.in_(group_ids),
        Message.expiry > now
    ).order_by(Message.priority.desc()).all()

    # Deduplicate by message ID (assuming message is unique to group)
    unique_messages = {}
    for msg in messages:
        key = msg.id  # could also be (msg.content, msg.expiry) for stricter rules
        if key not in unique_messages or msg.group_id < unique_messages[key].group_id:
            unique_messages[key] = msg

    return [
        {
            "id": msg.id,
            "group": msg.group.name,
            "content": msg.content,
            "priority": msg.priority.value,
            "expiry": msg.expiry.strftime("%Y-%m-%d %H:%M"),
            "timestamp": msg.timestamp.strftime("%Y-%m-%d %H:%M")
        }
        for msg in unique_messages.values()
    ]


@router.delete("/messages/{message_id}/")
def delete_message(message_id: int, db: Session = Depends(get_db)):
    message = db.query(Message).filter_by(id=message_id).first()
    if not message:
        raise HTTPException(status_code=404, detail="Message not found")
    db.delete(message)
    db.commit()
    return {"status": "Message deleted"}

@router.put("/messages/{message_id}/")
def update_message(message_id: int, data: dict, db: Session = Depends(get_db)):
    """
    Update a sent message's content, priority, or expiry.
    Expects a JSON body with any of: content, priority, expiry (as string 'YYYY-MM-DD' or 'YYYY-MM-DD HH:MM').
    """
    message = db.query(Message).filter_by(id=message_id).first()
    if not message:
        raise HTTPException(status_code=404, detail="Message not found")

    updated = False
    if 'content' in data:
        message.content = data['content']
        updated = True
    if 'priority' in data:
        message.priority = data['priority']
        updated = True
    if 'expiry' in data:
        try:
            # Try parsing with and without time
            try:
                message.expiry = datetime.strptime(data['expiry'], "%Y-%m-%d %H:%M")
            except ValueError:
                message.expiry = datetime.strptime(data['expiry'], "%Y-%m-%d")
            updated = True
        except Exception:
            raise HTTPException(status_code=400, detail="Invalid expiry format. Use YYYY-MM-DD or YYYY-MM-DD HH:MM")
    if not updated:
        raise HTTPException(status_code=400, detail="No valid fields to update.")
    db.commit()
    return {"status": "Message updated"}

