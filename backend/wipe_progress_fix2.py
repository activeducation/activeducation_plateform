import asyncio
from app.db.supabase_client import SupabaseClient
from dotenv import load_dotenv

load_dotenv()

async def wipe():
    print("Initializing SupabaseClient...")
    import os
    from supabase import create_client
    
    url = os.environ.get("SUPABASE_URL")
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    client = create_client(url, key)
    
    try:
        # Fetch all progress to get their IDs
        res = client.table('elearning_user_progress').select('*').execute()
        if res.data:
            print(f"Found {len(res.data)} progress records. Deleting...")
            for r in res.data:
                client.table('elearning_user_progress').delete().eq('user_id', r['user_id']).eq('lesson_id', r['lesson_id']).execute()
        else:
            print("No progress records found.")
    except Exception as e:
        print(f"Error wiping progress: {e}")

    try:
        res = client.table('elearning_enrollments').select('*').execute()
        if res.data:
            print(f"Found {len(res.data)} enrollments. Deleting...")
            for r in res.data:
                client.table('elearning_enrollments').delete().eq('user_id', r['user_id']).eq('course_id', r['course_id']).execute()
        else:
            print("No enrollments found.")
    except Exception as e:
        print(f"Error wiping enrollments: {e}")

if __name__ == "__main__":
    asyncio.run(wipe())
