import json
from pathlib import Path
from typing import Any


KNOWLEDGE_DIR = Path(__file__).parent


def load_exercises() -> dict[str, list[dict[str, Any]]]:
    path = KNOWLEDGE_DIR / "exercises.json"

    with open(path, "r", encoding="utf-8") as file:
        return json.load(file)


def get_all_exercises() -> list[dict[str, Any]]:
    data = load_exercises()

    exercises = []

    for category, category_exercises in data.items():
        for exercise in category_exercises:
            exercise_copy = exercise.copy()

            # Preserve the JSON category as searchable information.
            exercise_copy["category"] = category

            exercises.append(exercise_copy)

    return exercises

def matches_difficulty(
    exercise: dict[str, Any],
    difficulty: str | None,
) -> bool:

    if not difficulty:
        return True

    return (
        exercise.get("difficulty", "").lower()
        == difficulty.lower()
    )


def matches_category(
    exercise: dict[str, Any],
    category: str | None,
) -> bool:

    if not category:
        return True

    category = category.lower()

    exercise_category = exercise.get(
        "category",
        ""
    ).lower()

    if exercise_category == category:
        return True

    tags = [
        tag.lower()
        for tag in exercise.get("tags", [])
    ]

    return category in tags


def matches_muscle(
    exercise: dict[str, Any],
    muscle: str | None,
) -> bool:

    if not muscle:
        return True

    muscle = muscle.lower()

    muscles = []

    muscles.extend(
        exercise.get("primary_muscles", [])
    )

    muscles.extend(
        exercise.get("secondary_muscles", [])
    )

    muscles = [
        item.lower()
        for item in muscles
    ]

    return muscle in muscles


def matches_impact(
    exercise: dict[str, Any],
    impact_level: str | None,
) -> bool:

    if not impact_level:
        return True

    return (
        exercise.get("impact_level", "").lower()
        == impact_level.lower()
    )


def matches_equipment_constraint(
    exercise: dict[str, Any],
    available_equipment: list[str] | None,
) -> bool:

    if not available_equipment:
        return True

    exercise_equipment = (
        exercise.get("equipment", "")
        .lower()
    )

    available = [
        item.lower()
        for item in available_equipment
    ]

    if exercise_equipment == "bodyweight":
        return True

    return exercise_equipment in available


def retrieve_workouts(
    category: str | None = None,
    muscle: str | None = None,
    difficulty: str | None = None,
    equipment: list[str] | None = None,
    impact_level: str | None = None,
    limit: int = 10,
) -> list[dict[str, Any]]:

    exercises = get_all_exercises()

    results = []

    for exercise in exercises:

        if not matches_category(
            exercise,
            category
        ):
            continue

        if not matches_muscle(
            exercise,
            muscle
        ):
            continue

        if not matches_difficulty(
            exercise,
            difficulty
        ):
            continue

        if not matches_equipment_constraint(
            exercise,
            equipment
        ):
            continue

        if not matches_impact(
            exercise,
            impact_level
        ):
            continue

        results.append(exercise)

    return results[:limit]


def retrieve_low_impact_workouts(
    category: str | None = None,
    muscle: str | None = None,
    difficulty: str | None = None,
    equipment: list[str] | None = None,
    limit: int = 10,
) -> list[dict[str, Any]]:

    return retrieve_workouts(
        category=category,
        muscle=muscle,
        difficulty=difficulty,
        equipment=equipment,
        impact_level="low",
        limit=limit,
    )


def format_workout_results(
    exercises: list[dict[str, Any]]
) -> dict[str, Any]:

    return {
        "exercises": [
            {
                "name": exercise["name"],
                "category": exercise.get("category"),
                "equipment": exercise.get("equipment"),
                "difficulty": exercise.get("difficulty"),
                "primary_muscles": exercise.get(
                    "primary_muscles",
                    []
                ),
                "secondary_muscles": exercise.get(
                    "secondary_muscles",
                    []
                ),
                "movement_pattern": exercise.get(
                    "movement_pattern"
                ),
                "impact_level": exercise.get(
                    "impact_level"
                ),
                "regressions": exercise.get(
                    "regressions",
                    []
                ),
                "progressions": exercise.get(
                    "progressions",
                    []
                ),
                "tags": exercise.get(
                    "tags",
                    []
                )
            }
            for exercise in exercises
        ]
    }