import json
from pathlib import Path
from typing import Any


KNOWLEDGE_DIR = Path(__file__).parent


def load_knowledge(filename: str) -> dict[str, Any]:
    path = KNOWLEDGE_DIR / filename

    with open(path, "r", encoding="utf-8") as file:
        return json.load(file)