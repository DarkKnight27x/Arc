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

    # -------------------------
    # Workout knowledge
    # -------------------------

    if any(word in message_lower for word in [
        "workout",
        "exercise",
        "training",
        "core",
        "strength",
        "upper body",
        "lower body",
    ]):
        knowledge["exercises"] = load_knowledge("exercises.json")

    # -------------------------
    # Nutrition knowledge
    # -------------------------

    nutrition_requested = any(word in message_lower for word in [
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
    ])

    if nutrition_requested:

        nutrition = load_knowledge("nutrition.json")
        meals = load_knowledge("meals.json")

        foods = nutrition.get("foods", [])
        meal_list = meals.get("meals", [])

        # -------------------------
        # Detect meal type
        # -------------------------

        meal_type = None

        if "breakfast" in message_lower:
            meal_type = "breakfast"
        elif "lunch" in message_lower:
            meal_type = "lunch"
        elif "dinner" in message_lower:
            meal_type = "dinner"
        elif "snack" in message_lower:
            meal_type = "snack"

        # -------------------------
        # Detect diet preference
        # -------------------------

        diet = None

        if "non-vegetarian" in message_lower or "non vegetarian" in message_lower:
            diet = "non_vegetarian"
        elif "eggetarian" in message_lower:
            diet = "eggetarian"
        elif "vegetarian" in message_lower:
            diet = "vegetarian"

        # -------------------------
        # Detect nutrition goal
        # -------------------------

        high_protein = any(word in message_lower for word in [
            "high protein",
            "high-protein",
            "protein rich",
            "protein-rich"
        ])

        # -------------------------
        # Filter meals
        # -------------------------

        relevant_meals = []

        for meal in meal_list:

            # Meal type filter
            if meal_type is not None:
                if meal.get("meal_type") != meal_type:
                    continue

            tags = meal.get("dietary_tags", [])

            # Diet filter
            if diet == "vegetarian":
                if "vegetarian" not in tags:
                    continue

            elif diet == "eggetarian":
                if not (
                    "vegetarian" in tags
                    or "eggetarian" in tags
                ):
                    continue

            elif diet == "non_vegetarian":
                if "non_vegetarian" not in tags:
                    continue

            # Protein filter
            if high_protein:
                if "high_protein" not in tags:
                    continue

            relevant_meals.append(meal)

        # -------------------------
        # If there are no filters,
        # return a small default set
        # -------------------------

        if not meal_type and not diet and not high_protein:
            relevant_meals = meal_list[:10]

        # -------------------------
        # Resolve food references
        # -------------------------

        food_lookup = {
            food["name"]: food
            for food in foods
        }

        relevant_foods = {}

        meal_results = []

        for meal in relevant_meals:

            total_calories = 0
            total_protein = 0
            total_carbs = 0
            total_fat = 0
            total_fiber = 0

            valid_items = []

            for item_name in meal.get("items", []):

                food = food_lookup.get(item_name)

                if not food:
                    continue

                valid_items.append(item_name)
                relevant_foods[item_name] = food

                total_calories += food.get("calories_kcal", 0)
                total_protein += food.get("protein_g", 0)
                total_carbs += food.get("carbohydrates_g", 0)
                total_fat += food.get("fat_g", 0)
                total_fiber += food.get("fiber_g", 0)

            meal_results.append({
                "name": meal["name"],
                "meal_type": meal["meal_type"],
                "items": valid_items,
                "nutrition": {
                    "calories_kcal": total_calories,
                    "protein_g": total_protein,
                    "carbohydrates_g": total_carbs,
                    "fat_g": total_fat,
                    "fiber_g": total_fiber
                }
            })

        knowledge["nutrition"] = {
            "foods": list(relevant_foods.values())
        }

        knowledge["meals"] = {
            "meals": meal_results
        }

    # -------------------------
    # Adaptation knowledge
    # -------------------------

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

    # -------------------------
    # Safety knowledge
    # -------------------------

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