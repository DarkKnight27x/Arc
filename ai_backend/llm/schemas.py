from typing import Any, Literal

from pydantic import BaseModel, Field


class LLMToolCall(BaseModel):
    id: str
    name: str
    arguments: dict[str, Any] = Field(default_factory=dict)


class LLMResponse(BaseModel):
    type: Literal["tool_call", "final"]
    content: str | None = None
    tool_calls: list[LLMToolCall] = Field(default_factory=list)