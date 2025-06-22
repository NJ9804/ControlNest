from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

DATABASE_URL = "postgresql://data_owner:npg_Br59HfkJdwXv@ep-raspy-mountain-a15lgumk-pooler.ap-southeast-1.aws.neon.tech/data?sslmode=require"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
Base = declarative_base()
