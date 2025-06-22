from fastapi import APIRouter, HTTPException, Depends, UploadFile, File
from sqlalchemy.orm import Session
from sqlalchemy import func
from sqlalchemy.exc import OperationalError
from models import Group, Contact
from database import SessionLocal
import pandas as pd
from io import BytesIO

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def build_hierarchy(db, parent_id=None, path=''):
    groups = db.query(Group).filter_by(parent_id=parent_id).all()
    hierarchy = []
    for group in groups:
        full_path = f"{path}/{group.name}" if path else group.name
        hierarchy.append({
            "id": group.id,
            "name": group.name,
            "path": full_path,
            "contactCount": len(group.contacts),
            "children": build_hierarchy(db, group.id, full_path)
        })
    return hierarchy

@router.get("/groups/hierarchy/")
def get_group_hierarchy(group_name: str = None, db: Session = Depends(get_db)):
    if group_name:
        clean_name = group_name.strip()
        group = db.query(Group).filter(func.lower(Group.name) == clean_name.lower()).first()
        if not group:
            raise HTTPException(status_code=404, detail="Group not found")
        path = group.name
        children = build_hierarchy(db, group.id, path)
        return [{
            "id": group.id,
            "name": group.name,
            "path": path,
            "contactCount": len(group.contacts),
            "children": children
        }]
    else:
        return build_hierarchy(db)

@router.post("/upload-groups/")
async def upload_groups(file: UploadFile = File(...), db: Session = Depends(get_db)):
    try:
        contents = await file.read()
        df = pd.read_excel(BytesIO(contents))

        for _, row in df.iterrows():
            group_name = row['group_name']
            parent_name = row.get('parent_name')

            parent_id = None
            if pd.notna(parent_name):
                parent_group = db.query(Group).filter_by(name=parent_name).first()
                if not parent_group:
                    parent_group = Group(name=parent_name)
                    db.add(parent_group)
                    db.commit()
                    db.refresh(parent_group)
                parent_id = parent_group.id

            existing = db.query(Group).filter_by(name=group_name, parent_id=parent_id).first()
            if not existing:
                new_group = Group(name=group_name, parent_id=parent_id)
                db.add(new_group)
                db.commit()
    except OperationalError as e:
        raise HTTPException(status_code=500, detail="Database connection error. Please try again later.")

    return {"status": "Groups uploaded"}

