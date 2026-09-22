from typing import Any

from ai_backend.supabase_client import get_supabase_client
from ai_backend.tools.base import Tool


class GetCurrentWorkoutTool(Tool):
    name = "get_current_workout"
    description = (
        "Get the user's currently active workout plan, including the "
        "weekly workout days and exercises scheduled for each day."
    )

    def execute(
        self,
        user_id: str,
        arguments: dict[str, Any],
    ) -> dict[str, Any]:
        if not user_id:
            raise ValueError("get_current_workout requires a user_id")

        supabase = get_supabase_client()

        # 1. Get the user's active workout plan
        plan_response = (
            supabase
            .table("workout_plans")
            .select(
                "id, name, plan_type, status, version"
            )
            .eq("user_id", user_id)
            .eq("status", "active")
            .eq("plan_type", "training")
            .order("version", desc=True)
            .limit(1)
            .execute()
        )

        if not plan_response.data:
            return {
                "has_workout": False,
                "plan": None,
            }

        plan = plan_response.data[0]
        plan_id = plan["id"]

        # 2. Get all days belonging to this plan
        days_response = (
            supabase
            .table("workout_days")
            .select(
                "id, weekday, title, estimated_minutes, notes"
            )
            .eq("workout_plan_id", plan_id)
            .order("weekday")
            .execute()
        )

        days = days_response.data or []

        # 3. Get exercises for each day
        formatted_days = []

        for day in days:
            exercises_response = (
                supabase
                .table("workout_day_exercises")
                .select(
                    "id, exercise_id, sort_order, sets, reps, "
                    "rest_seconds, notes"
                )
                .eq("workout_day_id", day["id"])
                .order("sort_order")
                .execute()
            )

            exercise_rows = exercises_response.data or []

            exercises = []

            for exercise_row in exercise_rows:
                exercise_response = (
                    supabase
                    .table("exercise_library")
                    .select(
                        "id, name, body_part, target_muscle, "
                        "equipment, difficulty"
                    )
                    .eq("id", exercise_row["exercise_id"])
                    .limit(1)
                    .execute()
                )

                if not exercise_response.data:
                    continue

                exercise = exercise_response.data[0]

                exercises.append(
                    {
                        "name": exercise["name"],
                        "body_part": exercise["body_part"],
                        "target_muscle": exercise["target_muscle"],
                        "equipment": exercise["equipment"],
                        "difficulty": exercise["difficulty"],
                        "sets": exercise_row["sets"],
                        "reps": exercise_row["reps"],
                        "rest_seconds": exercise_row["rest_seconds"],
                        "notes": exercise_row["notes"],
                    }
                )

            formatted_days.append(
                {
                    "weekday": day["weekday"],
                    "title": day["title"],
                    "estimated_minutes": day["estimated_minutes"],
                    "notes": day["notes"],
                    "exercises": exercises,
                }
            )

        return {
            "has_workout": True,
            "plan": {
                "id": plan["id"],
                "name": plan["name"],
                "plan_type": plan["plan_type"],
                "status": plan["status"],
                "version": plan["version"],
                "days": formatted_days,
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
            "description": "Whether to include detailed exercise information.",
            "default": True,
        }
    },
    "additionalProperties": False,
},
            },
        }