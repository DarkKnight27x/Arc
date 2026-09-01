from typing import Any

from .loader import load_knowledge


def load_exercises() -> dict[str, list[dict[str, Any]]]:
    return load_knowledge("exercises.json")


def get_all_exercises() -> list[dict[str, Any]]:
    data = load_exercises()

    exercises = []

    for category, category_exercises in data.items():
        for exercise in category_exercises:
            exercise_copy = exercise.copy()
            exercise_copy["category"] = category
            exercises.append(exercise_copy)

    return exercises


def _contains(
    value: str | None,
    query: str | None,
) -> bool:
    if not value or not query:
        return False

    return query.lower() in value.lower()


def _list_contains(
    values: list[str],
    query: str | None,
) -> bool:
    if not query:
        return False

    query = query.lower()

    return any(
        query in value.lower()
        for value in values
    )


def _calculate_score(
    exercise: dict[str, Any],
    category: str | None,
    muscle: str | None,
    difficulty: str | None,
    equipment: list[str] | None,
    impact_level: str | None,
    movement_pattern: str | None,
) -> int:

    score = 0

    if category:
        if exercise["category"].lower() == category.lower():
            score += 5

    if muscle:
        primary_muscles = exercise.get(
            "primary_muscles",
            [],
        )

        secondary_muscles = exercise.get(
            "secondary_muscles",
            [],
        )

        if _list_contains(
            primary_muscles,
            muscle,
        ):
            score += 4

        elif _list_contains(
            secondary_muscles,
            muscle,
        ):
            score += 2

    if difficulty:
        if _contains(
            exercise.get("difficulty"),
            difficulty,
        ):
            score += 3

    if equipment:
        exercise_equipment = exercise.get(
            "equipment",
            "",
        ).lower()

        available_equipment = [
            item.lower()
            for item in equipment
        ]

        if exercise_equipment in available_equipment:
            score += 3

        elif exercise_equipment == "bodyweight":
            score += 1

    if impact_level:
        if _contains(
            exercise.get("impact_level"),
            impact_level,
        ):
            score += 3

    if movement_pattern:
        if _contains(
            exercise.get("movement_pattern"),
            movement_pattern,
        ):
            score += 2

    tags = exercise.get("tags", [])

    if category:
        if _list_contains(tags, category):
            score += 1

    if difficulty:
        if _list_contains(tags, difficulty):
            score += 1

    if impact_level:
        impact_tag = f"{impact_level}_impact"

        if _list_contains(tags, impact_tag):
            score += 1

    return score


def retrieve_workouts(
    category: str | None = None,
    muscle: str | None = None,
    difficulty: str | None = None,
    equipment: list[str] | None = None,
    impact_level: str | None = None,
    movement_pattern: str | None = None,
    limit: int = 5,
) -> list[dict[str, Any]]:

    exercises = get_all_exercises()
    candidates = []

    normalized_equipment = [
        item.lower()
        for item in (equipment or [])
    ]

    for exercise in exercises:

        # Hard filter: category
        if category:
            if exercise["category"].lower() != category.lower():
                continue

        # Hard filter: difficulty
        if difficulty:
            if exercise.get(
                "difficulty",
                "",
            ).lower() != difficulty.lower():
                continue

        # Hard filter: impact
        if impact_level:
            if exercise.get(
                "impact_level",
                "",
            ).lower() != impact_level.lower():
                continue

        # Hard filter: equipment
        if equipment:
            exercise_equipment = exercise.get(
                "equipment",
                "",
            ).lower()

            # Bodyweight exercises require no equipment.
            if exercise_equipment != "bodyweight":
                if exercise_equipment not in normalized_equipment:
                    continue

        score = _calculate_score(
            exercise=exercise,
            category=category,
            muscle=muscle,
            difficulty=difficulty,
            equipment=equipment,
            impact_level=impact_level,
            movement_pattern=movement_pattern,
        )

        exercise_with_score = exercise.copy()
        exercise_with_score["_relevance_score"] = score

        candidates.append(exercise_with_score)

    candidates.sort(
        key=lambda exercise: exercise["_relevance_score"],
        reverse=True,
    )

    return candidates[:limit]


def retrieve_low_impact_workouts(
    category: str | None = None,
    muscle: str | None = None,
    difficulty: str | None = None,
    equipment: list[str] | None = None,
    limit: int = 5,
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
    exercises: list[dict[str, Any]],
) -> dict[str, Any]:

    return {
        "exercises": [
            {
                "name": exercise.get("name"),
                "equipment": exercise.get("equipment"),
                "difficulty": exercise.get("difficulty"),
                "primary_muscles": exercise.get(
                    "primary_muscles",
                    [],
                ),
                "secondary_muscles": exercise.get(
                    "secondary_muscles",
                    [],
                ),
                "movement_pattern": exercise.get(
                    "movement_pattern",
                ),
                "impact_level": exercise.get(
                    "impact_level",
                ),
                "tags": exercise.get(
                    "tags",
                    [],
                ),
            }
            for exercise in exercises
        ]
    }