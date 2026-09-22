from ai_backend.context.schemas import (
    ActivityState,
    CoachContext,
    ConversationState,
    KnowledgeContext,
    PlanState,
    SafetyContext,
    UserState,
)


class ContextEngine:
    def build(
        self,
        user_id: str,
        current_message: str,
        user_data: dict | None = None,
        conversation: list[dict[str, str]] | None = None,
        knowledge: list[dict] | None = None,
        available_tools: list[str] | None = None,
    ) -> CoachContext:
        user_data = user_data or {}

        return CoachContext(
            user_id=user_id,
            current_message=current_message,

            user=UserState(
                profile=user_data.get("profile", {}),
                goals=user_data.get("goals", {}),
                preferences=user_data.get("preferences", {}),
                current_state=user_data.get("current_state", {}),
            ),

            plans=PlanState(
                workout_plan=user_data.get("workout_plan"),
                meal_plan=user_data.get("meal_plan"),
            ),

            activity=ActivityState(
                recent_workouts=user_data.get(
                    "recent_workouts", []
                ),
                recent_meals=user_data.get(
                    "recent_meals", []
                ),
                progress=user_data.get(
                    "progress", {}
                ),
            ),

            conversation=ConversationState(
                messages=conversation or []
            ),

            knowledge=KnowledgeContext(
                chunks=knowledge or []
            ),

            safety=SafetyContext(
                restrictions=user_data.get(
                    "restrictions", []
                ),
                flags=user_data.get(
                    "safety_flags", []
                ),
            ),

            available_tools=available_tools or [],
        )