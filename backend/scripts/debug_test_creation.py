
import asyncio
import sys
import os
import traceback

# Setup paths
current_dir = os.path.dirname(os.path.abspath(__file__))
backend_dir = os.path.dirname(current_dir) # d:/ActivEducation/backend
project_root = os.path.dirname(backend_dir) # d:/ActivEducation

sys.path.append(backend_dir)

output_file = os.path.join(backend_dir, "debug_output.txt")

def log(msg):
    print(msg)
    with open(output_file, "a", encoding="utf-8") as f:
        f.write(msg + "\n")

async def test_creation():
    try:
        log("Starting debug script...")
        log(f"Backend dir: {backend_dir}")
        
        from dotenv import load_dotenv
        
        # Load .env file explicitly
        env_path = os.path.join(backend_dir, ".env")
        load_dotenv(env_path)
        log(f"Loaded .env from {env_path}")

        # Set fallback env vars if .env missing/incomplete (for debug only)
        if not os.environ.get("SUPABASE_URL"):
             os.environ["SUPABASE_URL"] = "https://placeholder.supabase.co"
        if not os.environ.get("SUPABASE_KEY"):
             os.environ["SUPABASE_KEY"] = "placeholder"
        if not os.environ.get("SECRET_KEY"):
             os.environ["SECRET_KEY"] = "placeholder_secret_key_needs_to_be_long_enough_32_chars"

        from app.schemas.admin.orientation import TestCreate
        from app.repositories.admin.tests_repository import TestsAdminRepository
        from app.core.logging import setup_logging
        
        setup_logging()
        log("Logging setup complete.")
        from app.core.config import settings
        
        log(f"Settings loaded.")
        log(f"SUPABASE_URL: {settings.SUPABASE_URL}")
        
        key = settings.SUPABASE_KEY
        sr_key = settings.SUPABASE_SERVICE_ROLE_KEY
        
        log(f"SUPABASE_KEY present: {bool(key)}")
        log(f"SUPABASE_SERVICE_ROLE_KEY present: {bool(sr_key)}")
        
        if key and sr_key:
            if key == sr_key:
                log("WARNING: SUPABASE_SERVICE_ROLE_KEY is identical to SUPABASE_KEY (likely Anon key). RLS will block writes!")
            else:
                log("SUPABASE_SERVICE_ROLE_KEY is different from SUPABASE_KEY. Good.")
        
        repo = TestsAdminRepository()
        log("Repository initialized.")
        
        test_data = TestCreate(
            name="Test Creation Debug",
            description="Debugging admin creation via script.",
            type="riasec",
            duration_minutes=15,
            image_url="https://example.com/image.png",
            is_active=True,
            display_order=99
        )
        
        log(f"Attempting create with: {test_data.model_dump()}")
        
        new_test = await repo.create_test(test_data)
        log(f"SUCCESS! Created test ID: {new_test.id}")
        
        # Cleanup
        await repo.delete_test(new_test.id)
        log("Test deleted.")
        
    except Exception as e:
        log(f"ERROR: {str(e)}")
        log(traceback.format_exc())

if __name__ == "__main__":
    if os.path.exists(output_file):
        os.remove(output_file)
    asyncio.run(test_creation())
