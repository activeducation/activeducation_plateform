import asyncio
from app.db.supabase_client import SupabaseClient
from dotenv import load_dotenv

load_dotenv()

async def wipe():
    print("Initializing SupabaseClient...")
    db = SupabaseClient()
    
    # 1. Delete progress
    try:
        # Fetch all progress to get their IDs
        res = db.client.table('elearning_user_progress').select('id').execute()
        if res.data:
            ids = [r['id'] for r in res.data]
            print(f"Found {len(ids)} progress records. Deleting...")
            for pid in ids:
                db.client.table('elearning_user_progress').delete().eq('id', pid).execute()
        else:
            print("No progress records found.")
    except Exception as e:
        print(f"Error wiping progress: {e}")

    # 2. Delete enrollments
    try:
        res = db.client.table('elearning_enrollments').select('id').execute()
        if res.data:
            ids = [r['id'] for r in res.data]
            print(f"Found {len(ids)} enrollments. Deleting...")
            for eid in ids:
                db.client.table('elearning_enrollments').delete().eq('id', eid).execute()
        else:
            print("No enrollments found.")
    except Exception as e:
        print(f"Error wiping enrollments: {e}")

if __name__ == "__main__":
    asyncio.run(wipe())
