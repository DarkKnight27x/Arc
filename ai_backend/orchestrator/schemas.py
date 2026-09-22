from typing import Any

from pydantic import BaseModel, Field


class ToolCall(BaseModel):
    id: str
    name: str
    arguments: dict[str, Any] = Field(default_factory=dict)


class ToolResult(BaseModel):
    tool_call_id: str
    tool_name: str
    result: Any


class FinalResponse(BaseModel):
    message: str

    needs_follow_up: bool = False

    follow_up_question: str | None = None

    action: dict[str, Any] | None = None

    confirmation_required: bool = False


class OrchestratorResponse(BaseModel):
    response: FinalResponse

    tool_calls_made: list[ToolResult] = Field(
        default_factory=list
    )