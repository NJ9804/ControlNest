from fastapi import APIRouter, HTTPException, Depends, UploadFile, File
from sqlalchemy.orm import Session
from sqlalchemy import func
from sqlalchemy.exc import OperationalError
from models import Group, Contact, Message
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

def build_hierarchy(db: Session):
    groups = db.query(Group).all()
    group_map = {group.id: group for group in groups}

    # Map of parent_id -> list of child groups
    children_map = {}
    for group in groups:
        children_map.setdefault(group.parent_id, []).append(group)

    # Get direct contact counts per group
    contact_counts = dict(
        db.query(Group.id, func.count(Contact.id))
        .select_from(Group)
        .join(Group.contacts)
        .group_by(Group.id)
        .all()
    )

    # Recursive function to build tree with total contacts
    def build_node(group, path=''):
        full_path = f"{path}/{group.name}" if path else group.name
        children = children_map.get(group.id, [])
        child_nodes = [build_node(child, full_path) for child in children]

        total_contacts = contact_counts.get(group.id, 0) + sum(child['contactCount'] for child in child_nodes)

        return {
            "id": group.id,
            "name": group.name,
            "path": full_path,
            "contactCount": total_contacts,
            "children": child_nodes
        }

    # Start from root-level groups (parent_id=None)
    return [build_node(group) for group in children_map.get(None, [])]

@router.get("/groups/hierarchy/")
def get_group_hierarchy(group_name: str = None, db: Session = Depends(get_db)):
    groups = build_hierarchy(db)

    if group_name:
        clean_name = group_name.strip().lower()

        def find_group(node_list):
            for node in node_list:
                if node["name"].lower() == clean_name:
                    return node
                child_result = find_group(node["children"])
                if child_result:
                    return child_result
            return None

        group_data = find_group(groups)
        if not group_data:
            raise HTTPException(status_code=404, detail="Group not found")
        return [group_data]

    return groups

@router.post("/upload-groups/")
async def upload_groups(file: UploadFile = File(...), db: Session = Depends(get_db)):
    try:
        contents = await file.read()
        df = pd.read_excel(BytesIO(contents))

        for _, row in df.iterrows():
            group_name = str(row['group_name']).strip()
            parent_name = str(row['parent_name']).strip() if pd.notna(row.get('parent_name')) else None

            parent_id = None
            if parent_name:
                parent_group = db.query(Group).filter(func.lower(Group.name) == parent_name.lower()).first()
                if not parent_group:
                    parent_group = Group(name=parent_name)
                    db.add(parent_group)
                    db.commit()
                    db.refresh(parent_group)
                parent_id = parent_group.id

            existing = db.query(Group).filter(
                func.lower(Group.name) == group_name.lower(),
                Group.parent_id == parent_id
            ).first()

            if not existing:
                new_group = Group(name=group_name, parent_id=parent_id)
                db.add(new_group)
                db.commit()

        return {"status": "Groups uploaded"}

    except OperationalError:
        raise HTTPException(status_code=500, detail="Database connection error. Please try again later.")
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error processing file: {str(e)}")

@router.get("/stats/")
def get_group_stats(db: Session = Depends(get_db)):
    try:
        total_groups = db.query(Group).count()
        total_contacts = db.query(Contact).count()
        total_messages = db.query(func.count(Message.id)).scalar()

        return {
            "total_groups": total_groups,
            "total_contacts": total_contacts,
            "total_messages": total_messages
        }
    except OperationalError:
        raise HTTPException(status_code=500, detail="Database connection error. Please try again later.")
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error retrieving stats: {str(e)}")