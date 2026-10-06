import asyncio
import os
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text
from dotenv import load_dotenv

load_dotenv()

async def main():
    database_url = os.getenv("DATABASE_URL")
    if not database_url:
        print("DATABASE_URL not found")
        return
    
    # Handle the fact that some dialects use postgresql:// instead of postgres://
    if database_url.startswith("postgres://"):
        database_url = database_url.replace("postgres://", "postgresql+asyncpg://")
    elif database_url.startswith("postgresql://"):
        database_url = database_url.replace("postgresql://", "postgresql+asyncpg://")

    engine = create_async_engine(database_url)
    
    # 1. First, delete the course to force cascade delete (so we can re-insert freshly)
    async with engine.begin() as conn:
        print("Deleting existing course to clear old data...")
        await conn.execute(text("DELETE FROM elearning_courses WHERE id = 'a1000000-0000-0000-0000-000000000001'"))
    
    # 2. Now read the seed file and execute it
    with open("db/seed_elearning.sql", "r", encoding="utf-8") as f:
        sql = f.read()
    
    async with engine.begin() as conn:
        print("Executing seed_elearning.sql...")
        for statement in sql.split(';'):
            if statement.strip():
                try:
                    await conn.execute(text(statement))
                except Exception as e:
                    print(f"Error on statement: {e}")
                    
    print("Seed executed successfully.")

if __name__ == "__main__":
    asyncio.run(main())
