from .loader import load_knowledge
from .workout_retriever import retrieve_workouts, format_workout_results


def _detect_workout_category(message: str) -> str | None:
    message = message.lower()

    if "core" in message:
        return "core"

    if "upper body" in message or "upper-body" in message:
        return "upper_body"

    if "lower body" in message or "lower-body" in message:
        return "lower_body"

    return None


def _detect_difficulty(message: str) -> str | None:
    message = message.lower()

    if "beginner" in message:
        return "beginner"

    if "intermediate" in message:
        return "intermediate"

    if "advanced" in message:
        return "advanced"

    return None


def _detect_equipment(message: str) -> list[str] | None:
    message = message.lower()

    equipment = []

    if "dumbbell" in message:
        equipment.append("dumbbells")

    if "resistance band" in message or "resistance bands" in message:
        equipment.append("resistance band")

    if "bodyweight" in message or "no equipment" in message:
        equipment.append("bodyweight")

    return equipment or None


def _detect_impact_level(message: str) -> str | None:
    message = message.lower()

    if "low impact" in message or "low-impact" in message:
        return "low"

    if "high impact" in message or "high-impact" in message:
        return "high"

    if "medium impact" in message or "medium-impact" in message:
        return "medium"

    return None


def _get_workout_knowledge(
    message: str,
    context: dict | None = None,
) -> dict:

    category = _detect_workout_category(message)
    difficulty = _detect_difficulty(message)
    equipment = _detect_equipment(message)
    impact_level = _detect_impact_level(message)

    context = context or {}

    user = context.get("user", {})
    health_constraints = context.get(
        "health_constraints",
        {},
    )

    # Use the user's available equipment
    if equipment is None:
        equipment = user.get("equipment")

    # Respect known high-impact restrictions
    restrictions = health_constraints.get(
        "restrictions",
        [],
    )

    restrictions_text = " ".join(
        restriction.lower()
        for restriction in restrictions
    )

    if "high-impact" in restrictions_text:
        impact_level = "low"

    results = retrieve_workouts(
        category=category,
        difficulty=difficulty,
        equipment=equipment,
        impact_level=impact_level,
        limit=5,
    )

    return format_workout_results(results)


def get_relevant_knowledge(
    message: str,
    context: dict | None = None,
) -> dict:
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
        knowledge["exercises"] = _get_workout_knowledge(
    message,
    context,
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