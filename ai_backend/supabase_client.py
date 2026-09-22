from supabase import Client, create_client

from ai_backend.config import SUPABASE_KEY, SUPABASE_URL, validate_config


def get_supabase_client() -> Client:
    validate_config()

    return create_client(
        SUPABASE_URL,
        SUPABASE_KEY,
    )