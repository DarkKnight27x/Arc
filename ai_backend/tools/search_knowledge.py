from typing import Any

from ai_backend.rag.retriever import retrieve_knowledge
from ai_backend.tools.base import Tool


class SearchKnowledgeTool(Tool):
    name = "search_knowledge"

    description = (
        "Search Arc's general health and fitness knowledge base. "
        "Use this when domain knowledge is needed to answer the user. "
        "This does not search personal user data."
    )

    def execute(
        self,
        user_id: str,
        arguments: dict[str, Any],
    ) -> list[dict]:
        query = arguments.get("query")

        if not query or not isinstance(query, str):
            raise ValueError("search_knowledge requires a non-empty query")

        match_count = arguments.get("match_count", 5)

        if not isinstance(match_count, int):
            raise ValueError("match_count must be an integer")

        match_count = max(1, min(match_count, 10))

        knowledge_type = arguments.get("knowledge_type")

        allowed_types = {
            "workout_guidance",
            "nutrition_guidance",
            "safety_guidance",
            "rehab_guidance",
            "general_coaching",
        }

        if knowledge_type is not None:
            if knowledge_type not in allowed_types:
                raise ValueError(
                    f"Invalid knowledge_type: {knowledge_type}"
                )

        return retrieve_knowledge(
            query=query,
            match_count=match_count,
            knowledge_type=knowledge_type,
        )

    def schema(self) -> dict:
        return {
            "type": "function",
            "function": {
                "name": self.name,
                "description": self.description,
                "parameters": {
                    "type": "object",
                    "properties": {
                        "query": {
                            "type": "string",
                            "description": (
                                "The health or fitness question "
                                "to search for."
                            ),
                        },
                        "match_count": {
                            "type": "integer",
                            "description": (
                                "Number of knowledge chunks to retrieve. "
                                "Maximum is 10."
                            ),
                            "minimum": 1,
                            "maximum": 10,
                        },
                        "knowledge_type": {
                            "type": "string",
                            "enum": [
                                "workout_guidance",
                                "nutrition_guidance",
                                "safety_guidance",
                                "rehab_guidance",
                                "general_coaching",
                            ],
                        },
                    },
                    "required": ["query"],
                },
            },
        }