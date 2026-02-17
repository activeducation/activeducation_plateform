
import asyncio
import sys
from uuid import uuid4
import os

# Add backend directory to path
sys.path.append("d:/ActivEducation/backend")

from app.schemas.admin.orientation import TestCreate
from app.repositories.admin.tests_repository import TestsAdminRepository
from app.core.logging import setup_logging

def test_creation():
    setup_logging()
    
    repo = TestsAdminRepository()
    
    test_data = TestCreate(
        name="Test Creation Script",
        description="A test created via script to debug admin creation issues.",
        type="riasec",
        duration_minutes=15,
        image_url="https://example.com/image.png",
        is_active=True,
        display_order=99
    )
    
    print(f"Attempting to create test: {test_data.model_dump()}")
    
    try:
        new_test = asyncio.run(repo.create_test(test_data))
        print(f"SUCCESS! Created test with ID: {new_test.id}")
        
        # Clean up
        print(f"Cleaning up...")
        asyncio.run(repo.delete_test(new_test.id))
        print("Test deleted.")
        
    except Exception as e:
        print(f"FAILED! Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    test_creation()
