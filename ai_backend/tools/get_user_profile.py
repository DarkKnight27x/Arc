from typing import Any

from ai_backend.supabase_client import get_supabase_client
from ai_backend.tools.base import Tool


class GetUserProfileTool(Tool):
    name = "get_user_profile"

    description = (
        "Get the user's basic profile information, including display name, "
        "account type, and onboarding status."
    )

    def execute(
        self,
        user_id: str,
        arguments: dict[str, Any],
    ) -> dict[str, Any] | None:

        if not user_id:
            raise ValueError(
                "get_user_profile requires a user_id"
            )

        supabase = get_supabase_client()

        response = (
            supabase
            .table("profiles")
            .select(
                "user_id, display_name, account_type, onboarding_complete"
            )
            .eq("user_id", user_id)
            .limit(1)
            .execute()
        )

        if not response.data:
            return None

        return response.data[0]

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
                                "Whether to include the available "
                                "profile details."
                            ),
                            "default": True,
                        }
                    },
                    "additionalProperties": False,
                },
            },
        }