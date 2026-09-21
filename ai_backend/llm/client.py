import json
from typing import Any

from groq import Groq

from ai_backend.config import GROQ_API_KEY
from ai_backend.llm.schemas import LLMResponse


MODEL_NAME = "openai/gpt-oss-20b"


class LLMClient:
    def __init__(self) -> None:
        if not GROQ_API_KEY:
            raise RuntimeError("GROQ_API_KEY is not configured")

        self.client = Groq(api_key=GROQ_API_KEY)

    def generate(
        self,
        messages: list[dict[str, Any]],
        tools: list[dict[str, Any]] | None = None,
    ) -> LLMResponse:
        request: dict[str, Any] = {
            "model": MODEL_NAME,
            "messages": messages,
        }

        if tools:
            request["tools"] = tools

        response = self.client.chat.completions.create(**request)

        message = response.choices[0].message

        if message.tool_calls:
            tool_calls = []

            for tool_call in message.tool_calls:
                arguments = json.loads(tool_call.function.arguments)

                tool_calls.append(
                    {
                        "id": tool_call.id,
                        "name": tool_call.function.name,
                        "arguments": arguments,
                    }
                )

            return LLMResponse(
                type="tool_call",
                tool_calls=tool_calls,
            )

        return LLMResponse(
            type="final",
            content=message.content or "",
        )