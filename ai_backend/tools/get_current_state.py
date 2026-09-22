from typing import Any

from ai_backend.supabase_client import get_supabase_client
from ai_backend.tools.base import Tool


class GetCurrentStateTool(Tool):
    name = "get_current_state"

    description = (
        "Get the user's current health state, including whether they are "
        "sick, their reported illness, symptoms, injuries, and recovery status."
    )

    def execute(
        self,
        user_id: str,
        arguments: dict[str, Any],
    ) -> dict[str, Any]:

        if not user_id:
            raise ValueError(
                "get_current_state requires a user_id"
            )

        supabase = get_supabase_client()

        response = (
            supabase
            .table("profiles")
            .select("user_state")
            .eq("user_id", user_id)
            .limit(1)
            .execute()
        )

        if not response.data:
            return {}

        return response.data[0].get("user_state") or {}

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
                                "Whether to include the full current "
                                "health state."
                            ),
                            "default": True,
                        }
                    },
                    "additionalProperties": False,
                },
            },
        }