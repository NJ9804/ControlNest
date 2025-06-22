# upload.py
from fastapi import APIRouter, HTTPException, UploadFile, File, Depends
from sqlalchemy.orm import Session
from database import SessionLocal
from models import Group, Contact
import pandas as pd
from io import BytesIO

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/upload-contacts/{group_id}/")
async def upload_contacts(group_id: int, file: UploadFile = File(...), db: Session = Depends(get_db)):
    contents = await file.read()
    df = pd.read_excel(BytesIO(contents))

    for _, row in df.iterrows():
        name = row["name"]
        phone = row["phone"]

        contact = db.query(Contact).filter_by(phone_number=str(phone)).first()
        if contact:
            if not any(g.id == group_id for g in contact.groups):
                contact.groups.append(db.query(Group).get(group_id))
        else:
            contact = Contact(name=name, phone_number=phone)
            contact.groups.append(db.query(Group).get(group_id))
            db.add(contact)

    db.commit()
    return {"status": "Contacts uploaded"}


@router.post("/register-device/{device_id}/{phone_number}")
async def register_device(device_id: str, phone_number: str, db: Session = Depends(get_db)):
    contact = db.query(Contact).filter_by(phone_number=phone_number).first()
    
    if not contact:
        raise HTTPException(status_code=404, detail="No contact found with this phone number")

    contact.device_id = device_id
    db.commit()

    return {"status": "Device registered/updated", "name": contact.name, "device_id": contact.device_id}