import asyncio
from app.db.supabase_client import SupabaseClient
import os
from dotenv import load_dotenv

load_dotenv()

async def wipe():
    print("Initializing SupabaseClient...")
    db = SupabaseClient()
    
    # 1. Delete all progress for course Introduction aux métiers du numérique
    # Wait, it's easier to just wipe everything for test users. Or we wipe the whole table if it's a test env.
    print("Wiping elearning_user_progress...")
    # we can't easily run delete without filter in supabase python client without a condition
    # we'll use a condition that is always true
    try:
        res1 = db.client.table('elearning_user_progress').delete().neq("status", "fake_status_to_delete_all").execute()
        print(f"Deleted {len(res1.data) if res1.data else 0} progress records.")
    except Exception as e:
        print(f"Error wiping progress: {e}")

    try:
        print("Wiping elearning_enrollments...")
        res2 = db.client.table('elearning_enrollments').delete().neq("progress_pct", -1).execute()
        print(f"Deleted {len(res2.data) if res2.data else 0} enrollments.")
    except Exception as e:
        print(f"Error wiping enrollments: {e}")
        
    try:
        print("Wiping user badges (gamification)...")
        res3 = db.client.table('user_badges').delete().neq("badge_id", "dummy").execute()
        print(f"Deleted {len(res3.data) if res3.data else 0} badges.")
    except Exception as e:
        print(f"Error wiping badges: {e}")

if __name__ == "__main__":
    asyncio.run(wipe())
