from typing import Any

from ai_backend.supabase_client import get_supabase_client
from ai_backend.tools.base import Tool


ALLOWED_FIELDS = {
    "is_sick",
    "illness",
    "symptoms",
    "injuries",
    "recovery_status",
}


class UpdateUserStateTool(Tool):
    name = "update_user_state"

    description = (
        "Update specific fields in the user's current health state. "
        "Use only for user-reported changes such as sickness, symptoms, "
        "injuries, or recovery status."
    )

    def execute(
        self,
        user_id: str,
        arguments: dict[str, Any],
    ) -> dict[str, Any]:

        if not user_id:
            raise ValueError(
                "update_user_state requires a user_id"
            )

        updates = arguments.get("updates")

        if not isinstance(updates, dict) or not updates:
            raise ValueError(
                "update_user_state requires a non-empty updates object"
            )

        invalid_fields = set(updates) - ALLOWED_FIELDS

        if invalid_fields:
            raise ValueError(
                "Unsupported user state fields: "
                + ", ".join(sorted(invalid_fields))
            )

        supabase = get_supabase_client()

        current_response = (
            supabase
            .table("profiles")
            .select("user_state")
            .eq("user_id", user_id)
            .limit(1)
            .execute()
        )

        if not current_response.data:
            raise ValueError(
                "User profile not found"
            )

        current_state = (
            current_response.data[0].get("user_state")
            or {}
        )

        updated_state = {
            **current_state,
            **updates,
        }

        update_response = (
            supabase
            .table("profiles")
            .update(
                {
                    "user_state": updated_state,
                }
            )
            .eq("user_id", user_id)
            .execute()
        )

        if not update_response.data:
            raise RuntimeError(
                "Failed to update user state"
            )

        return {
            "updated": True,
            "user_state": updated_state,
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
                        "updates": {
                            "type": "object",
                            "description": (
                                "Fields to update in the user's current "
                                "health state."
                            ),
                            "properties": {
                                "is_sick": {
                                    "type": "boolean",
                                },
                                "illness": {
                                    "type": [
                                        "string",
                                        "null",
                                    ],
                                },
                                "symptoms": {
                                    "type": "array",
                                    "items": {
                                        "type": "string",
                                    },
                                },
                                "injuries": {
                                    "type": "array",
                                    "items": {
                                        "type": "string",
                                    },
                                },
                                "recovery_status": {
                                    "type": [
                                        "string",
                                        "null",
                                    ],
                                },
                            },
                            "additionalProperties": False,
                        }
                    },
                    "required": ["updates"],
                    "additionalProperties": False,
                },
            },
        }