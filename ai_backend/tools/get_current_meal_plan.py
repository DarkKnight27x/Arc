from typing import Any

from ai_backend.supabase_client import get_supabase_client
from ai_backend.tools.base import Tool


class GetCurrentMealPlanTool(Tool):
    name = "get_current_meal_plan"
    description = (
        "Get the user's currently active meal plan, including the "
        "weekly meals scheduled for breakfast, lunch, dinner, and snacks."
    )

    def execute(
        self,
        user_id: str,
        arguments: dict[str, Any],
    ) -> dict[str, Any]:
        if not user_id:
            raise ValueError("get_current_meal_plan requires a user_id")

        supabase = get_supabase_client()

        plan_response = (
            supabase
            .table("meal_plans")
            .select("id, name, status, version")
            .eq("user_id", user_id)
            .eq("status", "active")
            .order("version", desc=True)
            .limit(1)
            .execute()
        )

        if not plan_response.data:
            return {
                "has_meal_plan": False,
                "plan": None,
            }

        plan = plan_response.data[0]
        plan_id = plan["id"]

        items_response = (
            supabase
            .table("meal_plan_items")
            .select(
                "id, weekday, meal_type, meal_id, servings, notes"
            )
            .eq("meal_plan_id", plan_id)
            .order("weekday")
            .execute()
        )

        items = items_response.data or []

        if not items:
            return {
                "has_meal_plan": True,
                "plan": {
                    "id": plan["id"],
                    "name": plan["name"],
                    "status": plan["status"],
                    "version": plan["version"],
                    "days": [],
                },
            }

        meal_ids = list({
            item["meal_id"]
            for item in items
        })

        meals_response = (
            supabase
            .table("meals")
            .select(
                "id, name, meal_type, description, "
                "cuisine, default_servings"
            )
            .in_("id", meal_ids)
            .execute()
        )

        meals = {
            meal["id"]: meal
            for meal in (meals_response.data or [])
        }

        formatted_days = {}

        for item in items:
            weekday = item["weekday"]
            meal = meals.get(item["meal_id"])

            if not meal:
                continue

            if weekday not in formatted_days:
                formatted_days[weekday] = {
                    "weekday": weekday,
                    "meals": [],
                }

            formatted_days[weekday]["meals"].append(
                {
                    "meal_type": item["meal_type"],
                    "name": meal["name"],
                    "description": meal["description"],
                    "cuisine": meal["cuisine"],
                    "servings": item["servings"],
                    "notes": item["notes"],
                }
            )

        return {
            "has_meal_plan": True,
            "plan": {
                "id": plan["id"],
                "name": plan["name"],
                "status": plan["status"],
                "version": plan["version"],
                "days": list(formatted_days.values()),
            },
        }

    def schema(self) -> dict[str, Any]:
        return {
            "type": "function",
            "function": {
                "name": self.name,
                "description": self.description,
                "parameters": {
                    "type": "object",
                    "properties": {
                        "include_details": {
                            "type": "boolean",
                            "description": (
                                "Whether to include meal descriptions "
                                "and cuisine information."
                            ),
                            "default": True,
                        }
                    },
                    "additionalProperties": False,
                },
            },
        }