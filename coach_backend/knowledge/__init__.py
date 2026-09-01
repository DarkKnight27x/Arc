from .loader import load_knowledge


def get_relevant_knowledge(message: str) -> dict:
    message_lower = message.lower()

    knowledge = {}

    # Workout knowledge
    if any(word in message_lower for word in [
        "workout",
        "exercise",
        "training",
        "core",
        "strength",
        "upper body",
        "lower body",
    ]):
        knowledge["exercises"] = load_knowledge(
            "exercises.json"
        )

    # Nutrition knowledge
    if any(word in message_lower for word in [
        "diet",
        "food",
        "meal",
        "cuisine",
        "eat",
        "breakfast",
        "lunch",
        "dinner",
        "snack",
        "protein",
        "calorie",
        "calories",
        "nutrition",
        "carbs",
        "carbohydrates",
        "fat",
        "fiber",
        "vegetarian",
        "eggetarian",
        "non-vegetarian",
    ]):
        knowledge["nutrition"] = load_knowledge(
            "nutrition.json"
        )

        knowledge["meals"] = load_knowledge(
            "meals.json"
        )

    # Adaptation knowledge
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
        knowledge["adaptations"] = load_knowledge(
            "adaptations.json"
        )

    # Safety knowledge
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
        knowledge["safety"] = load_knowledge(
            "safety.json"
        )

    return knowledge