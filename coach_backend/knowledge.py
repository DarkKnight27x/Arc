import json
from pathlib import Path


KNOWLEDGE_DIR = Path(__file__).parent / "knowledge"


def load_knowledge(filename: str) -> dict:
    path = KNOWLEDGE_DIR / filename

    with open(path, "r", encoding="utf-8") as file:
        return json.load(file)


def get_relevant_knowledge(message: str) -> dict:
    message_lower = message.lower()

    knowledge = {}

    if any(word in message_lower for word in [
        "workout",
        "exercise",
        "training",
        "core",
        "strength",
    ]):
        knowledge["exercises"] = load_knowledge("exercises.json")

    if any(word in message_lower for word in [
        "diet",
        "food",
        "meal",
        "cuisine",
        "eat",
    ]):
        knowledge["meals"] = load_knowledge("meals.json")

    if any(word in message_lower for word in [
        "travel",
        "travelling",
        "traveling",
        "tired",
        "energy",
        "missed",
        "injury",
        "injured",
        "pain",
        "sick",
        "sickness",
    ]):
        knowledge["adaptations"] = load_knowledge("adaptations.json")

    if any(word in message_lower for word in [
        "pain",
        "injury",
        "injured",
        "sick",
        "sickness",
        "swelling",
        "breathing",
        "chest",
    ]):
        knowledge["safety"] = load_knowledge("safety.json")

    return knowledge