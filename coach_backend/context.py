import json
from pathlib import Path
from typing import Any


DATA_DIR = Path(__file__).parent / "data"
DEMO_USER_FILE = DATA_DIR / "demo_user.json"


def get_user_context(user_id: str = "demo_user") -> dict[str, Any]:
    with open(DEMO_USER_FILE, "r", encoding="utf-8") as file:
        context = json.load(file)

    if context["user"]["id"] != user_id:
        raise ValueError(f"User '{user_id}' not found")

    return context