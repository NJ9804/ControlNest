from fastapi import FastAPI, HTTPException, Depends
from sqlalchemy.orm import Session
from database import SessionLocal, engine
import models, schemas
import firebase_admin
from firebase_admin import messaging, credentials
from typing import List

from datetime import datetime, timezone
now = datetime.now(timezone.utc)


# Create DB tables
models.Base.metadata.create_all(bind=engine)

# Firebase init
cred = credentials.Certificate("firebase_config.json")
firebase_admin.initialize_app(cred)

app = FastAPI()

# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Mock allowed list
ALLOWED_MOBILE_NUMBERS = {"9999999999", "8888888888", "7777777777","8590449717"}

@app.post("/register")
def register(req: schemas.RegisterRequest, db: Session = Depends(get_db)):
    if req.mobile not in ALLOWED_MOBILE_NUMBERS:
        raise HTTPException(status_code=403, detail="Mobile number not allowed")

    # Remove any existing mapping for this fcm_token (remap token to new mobile)
    existing_token_entry = db.query(models.FCMToken).filter(models.FCMToken.fcm_token == req.fcm_token).first()
    if existing_token_entry and existing_token_entry.mobile != req.mobile:
        db.delete(existing_token_entry)
        db.commit()

    token_entry = db.query(models.FCMToken).filter(models.FCMToken.mobile == req.mobile).first()
    if token_entry:
        token_entry.fcm_token = req.fcm_token
    else:
        token_entry = models.FCMToken(mobile=req.mobile, fcm_token=req.fcm_token)
        db.add(token_entry)
    db.commit()
    return {"message": "FCM token saved successfully"}

@app.post("/send-msg")
def send_msg(req: schemas.SendMessageRequest, db: Session = Depends(get_db)):
    token_entry = db.query(models.FCMToken).filter(models.FCMToken.mobile == req.mobile).first()
    if not token_entry:
        raise HTTPException(status_code=404, detail="Mobile number not registered")

    message = messaging.Message(
        notification=messaging.Notification(
            title="New Message",
            body=req.message
        ),
        token=token_entry.fcm_token
    )

    response = messaging.send(message)

    # Save the sent message to the database with all details from the request
    msg = models.Message(
        mobile=req.mobile,
        message=req.message,
        visible_upto=req.visible_upto,
        priority=req.priority
    )
    db.add(msg)
    db.commit()
    db.refresh(msg)

    return {
        "message": "Message sent and saved",
        "firebase_response": response,
        "saved_message_id": msg.id
    }

@app.get("/messages/{mobile}", response_model=List[schemas.MessageResponse])
def get_messages(mobile: str, db: Session = Depends(get_db)):
    # Check if mobile is registered
    token_entry = db.query(models.FCMToken).filter(models.FCMToken.mobile == mobile).first()
    if not token_entry:
        raise HTTPException(status_code=404, detail="Mobile number not registered")
    
    now = datetime.now(timezone.utc)  # timezone-aware

    messages = db.query(models.Message).filter(
        models.Message.mobile == mobile,
        models.Message.visible_upto >= now
    ).order_by(
        models.Message.priority.desc(),
        models.Message.visible_upto.desc()
    ).all()

    return messages