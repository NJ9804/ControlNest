
from fastapi import FastAPI
from database import engine
from models import Base
from routers import groups,messages,upload
from fastapi.middleware.cors import CORSMiddleware
import firebase_admin
from firebase_admin import credentials

cred = credentials.Certificate("firebase_config.json")
firebase_admin.initialize_app(cred)

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # or ["*"] to allow all
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

Base.metadata.create_all(bind=engine)


app.include_router(groups.router, prefix="/api")
app.include_router(messages.router, prefix="/api")
app.include_router(upload.router, prefix="/api")