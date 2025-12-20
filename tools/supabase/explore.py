# /// script
# requires-python = ">=3.12"
# dependencies = [
#   "python-dotenv>=1.2.1",
#   "supabase>=2.27.0",
# ]
# ///
"""
This script explores the Supabase API and can create dummy data for testing the sync.

Run it via
```sh
uv run explore.py
```
"""

import pathlib
import sys
import time
from datetime import datetime, timezone

from dotenv import dotenv_values  # pyright: ignore[reportMissingImports]
from supabase import create_client, Client as SupabaseClient

FILE_PATH = pathlib.Path(__file__).parent.absolute()

config = dotenv_values(FILE_PATH / ".env")
SUPABASE_URL = config["SUPABASE_URL"]
SUPABASE_KEY = config["SUPABASE_KEY"]
USER_EMAIL = config["USER_EMAIL"]
USER_PASSWORD = config["USER_PASSWORD"]


# Utils ------------------------------------------------------------------------------------------------
def iso(dt: datetime) -> str:
    return dt.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")


# Auth ------------------------------------------------------------------------------------------------
def register(supabase: SupabaseClient, email: str, password: str):
    """
    Register a new user. Returns (user, session, needs_confirmation).
    If email confirmation is enabled, session will be None and needs_confirmation will be True.
    """
    resp = supabase.auth.sign_up({"email": email, "password": password})
    needs_confirmation = resp.session is None
    return resp.user, resp.session, needs_confirmation


def login(supabase: SupabaseClient, email: str, password: str) -> str:
    """
    Login user and return access token.
    Raises AuthApiError if email is not confirmed.
    """
    resp = supabase.auth.sign_in_with_password({"email": email, "password": password})
    if resp.session is None:
        raise ValueError("Login failed: No session returned")
    # access_token is what you send as Bearer for REST/RLS
    return resp.session.access_token


# Workotus ------------------------------------------------------------------------------------------------
def create_workout_with_sets(supabase: SupabaseClient):
    # Create parent workout (user_id will be set by your trigger)
    workout_id = (
        supabase.table("workouts")
        .insert(
            {
                "workout_type": "maxSets",
                "max_groups": 5,
                "start": iso(datetime.now(timezone.utc)),
                "end": iso(datetime.now(timezone.utc)),
            }
        )
        .execute()
        .data[0]["id"]
    )

    # Create nested children (sets) referencing the parent
    supabase.table("workout_sets").insert(
        [
            {
                "workout_id": workout_id,
                "number": 1,
                "group_number": 1,
                "target_reps": None,
                "completed_reps": 8,
            },
            {
                "workout_id": workout_id,
                "number": 2,
                "group_number": 2,
                "target_reps": None,
                "completed_reps": 7,
            },
            {
                "workout_id": workout_id,
                "number": 3,
                "group_number": 3,
                "target_reps": None,
                "completed_reps": 5,
            },
        ]
    ).execute().data
    return workout_id


def list_workouts_with_sets(
    supabase: SupabaseClient, since: datetime | None = None
) -> None:
    # Resource embedding uses foreign keys; this works because workout_sets.workout_id -> workouts.id
    # PostgREST resource embedding: select=*,workout_sets(*)  [oai_citation:6‡PostgREST 14](https://docs.postgrest.org/en/stable/references/api/resource_embedding.html?utm_source=chatgpt.com)
    selected = supabase.table("workouts").select("*,workout_sets(*)")
    if since:
        # Filter for workouts where either 'end' or 'deleted_at' is >= since
        selected = selected.or_(f"end.gte.{iso(since)},deleted_at.gte.{iso(since)}")
    workouts = selected.order("start", desc=True).execute().data
    print(f"Found {len(workouts)} workout(s):", workouts)


def soft_delete_workout(supabase: SupabaseClient, workout_id: int) -> None:
    # Soft delete parent; ON DELETE CASCADE isn't used here since it's not a hard delete.
    (
        supabase.table("workouts")
        .update({"deleted_at": iso(datetime.now(timezone.utc))})
        .eq("id", workout_id)
        .execute()
    )


if __name__ == "__main__":
    # 0) Initialize Supabase client
    _supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

    # # 1) register (may require email confirmation depending on project setting)
    # print("--- Registering user ---")
    # user, session, needs_confirmation = register(_supabase, USER_EMAIL, USER_PASSWORD)
    # print(f"User registered: {user.id}")
    # print(f"Email: {user.email}")
    # print(f"Email confirmed: {user.email_confirmed_at is not None}")
    # if needs_confirmation:
    #     print("\n⚠️  Email confirmation required!")
    #     print(
    #         "Click the confirmation link in the email you received (don't worry if you receive a 404, the confirmation still works)."
    #     )
    #     input("\nPress any key to continue")

    # 2) login -> access_token
    print("\n--- Logging in ---")
    try:
        _access_token = login(_supabase, USER_EMAIL, USER_PASSWORD)
        print(f"✅ Token acquired: {_access_token[:16]}...")
    except Exception as e:
        print(f"❌ Login failed: {e}")
        sys.exit(1)
    else:
        # Attach the user JWT to this client for subsequent calls
        _supabase.postgrest.auth(_access_token)

    # 3) create workout + sets
    print("\n--- Creating workout with sets ---")
    _workout_id = create_workout_with_sets(_supabase)
    print("Workout ID:", _workout_id)

    # 4) list all workouts
    print("\n--- Listing workouts (all) ---")
    list_workouts_with_sets(_supabase)

    # 5) soft delete
    print("\n--- Soft deleting workout ---")
    soft_delete_workout(_supabase, _workout_id)

    # 6) list all workouts again (the deleted workout is still listed)
    print("\n--- Listing workouts (all) ---")
    list_workouts_with_sets(_supabase)

    time.sleep(1)

    # 7) list all workouts again (the deleted workout shouldn't be listed)
    print("\n--- Listing all workouts (since now) ---")
    list_workouts_with_sets(_supabase, since=datetime.now(timezone.utc))
