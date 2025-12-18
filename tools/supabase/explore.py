# /// script
# requires-python = ">=3.12"
# dependencies = [
#   "python-dotenv>=1.2.1",
#   "supabase>=2.27.0",
# ]
# ///
# run this script via `uv run explore.py`


from datetime import datetime, timezone
import pathlib
import time
from urllib.parse import urlparse, parse_qs

from dotenv import dotenv_values
from supabase import create_client, Client

FILE_PATH = pathlib.Path(__file__).parent.absolute()

config = dotenv_values(FILE_PATH / ".env")

SUPABASE_URL = config["SUPABASE_URL"]
SUPABASE_KEY = config["SUPABASE_KEY"]
USER_EMAIL = config["USER_EMAIL"]
USER_PASSWORD = config["USER_PASSWORD"]

def iso(dt: datetime) -> str:
    return dt.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")

def extract_token_from_url(url_or_token: str) -> str:
    """
    Extract the token from a confirmation URL or return the token if it's already just a token.
    Supports URLs like: https://...supabase.co/auth/v1/verify?token=xxx&type=signup
    """
    url_or_token = url_or_token.strip()

    # If it looks like a URL (starts with http:// or https://), parse it
    if url_or_token.startswith(("http://", "https://")):
        try:
            parsed = urlparse(url_or_token)
            query_params = parse_qs(parsed.query)
            if "token" in query_params:
                token = query_params["token"][0]
                return token
            else:
                raise ValueError("No 'token' parameter found in the URL")
        except Exception as e:
            raise ValueError(f"Failed to parse URL: {e}")
    else:
        # Assume it's already a token
        return url_or_token

# ---------- Supabase client ----------
supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

# 1) User registration
def register(email: str, password: str):
    """
    Register a new user. Returns (user, session, needs_confirmation).
    If email confirmation is enabled, session will be None and needs_confirmation will be True.
    """
    resp = supabase.auth.sign_up({"email": email, "password": password})
    needs_confirmation = resp.session is None
    return resp.user, resp.session, needs_confirmation

# 2) Verify email with confirmation token
def verify_email(token: str):
    """
    Verify email using the confirmation token from the email link.
    The token can be extracted from the confirmation URL sent to the user's email.
    Example URL: https://<project>.supabase.co/auth/v1/verify?token=xxx&type=signup
    Extract the 'token' parameter value and pass it here.
    """
    resp = supabase.auth.verify_otp({
        "token": token,
        "type": "signup"
    })
    return resp

# 3) Resend confirmation email
def resend_confirmation_email(email: str, redirect_to: str = None):
    """
    Resend the email confirmation link to the user.
    """
    options = {"email": email}
    if redirect_to:
        options["redirect_to"] = redirect_to
    resp = supabase.auth.resend({
        "type": "signup",
        **options
    })
    return resp

# 4) User login
def login(email: str, password: str) -> str:
    """
    Login user and return access token.
    Raises AuthApiError if email is not confirmed.
    """
    resp = supabase.auth.sign_in_with_password({"email": email, "password": password})
    if resp.session is None:
        raise ValueError("Login failed: No session returned")
    # access_token is what you send as Bearer for REST/RLS
    return resp.session.access_token

# 5) POST main resource + nested resource
def create_workout_with_sets(access_token: str):
    # Attach the user JWT to this client for subsequent calls
    supabase.postgrest.auth(access_token)

    # Create parent workout (user_id will be set by your trigger)
    workout = (
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
        .data[0]
    )

    workout_id = workout["id"]

    # Create nested children (sets) referencing the parent
    sets_payload = [
        {"workout_id": workout_id, "group_number": 1, "target_reps": None, "completed_reps": 8},
        {"workout_id": workout_id, "group_number": 2, "target_reps": None, "completed_reps": 7},
        {"workout_id": workout_id, "group_number": 3, "target_reps": None, "completed_reps": 5},
    ]

    created_sets = supabase.table("workout_sets").insert(sets_payload).execute().data
    return workout, created_sets

# 6) GET all workouts with nested sets + updated_at >= param
def list_workouts_with_sets(access_token: str, updated_at_gte: datetime | None = None):
    supabase.postgrest.auth(access_token)

    # Resource embedding uses foreign keys; this works because workout_sets.workout_id -> workouts.id
    # PostgREST resource embedding: select=*,workout_sets(*)  [oai_citation:6‡PostgREST 14](https://docs.postgrest.org/en/stable/references/api/resource_embedding.html?utm_source=chatgpt.com)
    selected = supabase.table("workouts").select("*,workout_sets(*)")
    if updated_at_gte:
        selected = selected.gte("updated_at", iso(updated_at_gte))
    return selected.order("start", desc=True).execute().data

# 7) DELETE request (soft delete recommended)
def soft_delete_workout(access_token: str, workout_id: int):
    supabase.postgrest.auth(access_token)

    # Soft delete parent; ON DELETE CASCADE isn't used here since it's not a hard delete.
    deleted = (
        supabase.table("workouts")
        .update({"deleted_at": iso(datetime.now(timezone.utc))})
        .eq("id", workout_id)
        .execute()
        .data
    )

    return deleted


if __name__ == "__main__":
    import sys

    # # 1) register (may require email confirmation depending on project setting)
    # print("--- Registering user ---")
    # user, session, needs_confirmation = register(USER_EMAIL, USER_PASSWORD)
    # print(f"User registered: {user.id}")
    # print(f"Email: {user.email}")
    # print(f"Email confirmed: {user.email_confirmed_at is not None}")

    # if needs_confirmation:
    #     print("\n⚠️  Email confirmation required!")
    #     print("Check your email for the confirmation link.")
    #     input("\nPress any key to continue")

    # 2) login -> access_token
    print("\n--- Logging in ---")
    try:
        token = login(USER_EMAIL, USER_PASSWORD)
        print(f"✅ Token acquired: {token[:16]}...")
    except Exception as e:
        print(f"❌ Login failed: {e}")
        sys.exit(1)

    # 3) create workout + sets
    print("\n--- Creating workout with sets ---")
    workout, sets_ = create_workout_with_sets(token)
    print("Workout:", workout)
    print("Sets:", sets_)

    # 4) list since timestamp
    print("\n--- Listing workouts (all) ---")
    workouts = list_workouts_with_sets(token)
    print(f"Found {len(workouts)} workout(s):", workouts)

    # 5) soft delete
    print("\n--- Soft deleting workout ---")
    print("Soft delete result:", soft_delete_workout(token, workout["id"]))

    # 6) list all workouts again (the deleted workout is still listed)
    print("\n--- Listing workouts (all) ---")
    workouts = list_workouts_with_sets(token)
    print(f"Found {len(workouts)} workout(s):", workouts)

    time.sleep(1)

    # 7) list all workouts again (the deleted workout shouldn't be listed)
    print("\n--- Listing all workouts (since now) ---")
    workouts = list_workouts_with_sets(token, updated_at_gte=datetime.now(timezone.utc))
    print(f"Found {len(workouts)} workout(s):", workouts)
