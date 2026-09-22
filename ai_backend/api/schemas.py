from typing import Any

from pydantic import BaseModel, Field


class ConversationMessage(BaseModel):
    role: str
    content: str


class CoachRequest(BaseModel):
    user_id: str
    conversation_id: str
    message: str
    conversation: list[ConversationMessage] = Field(
        default_factory=list
    )


class FollowUp(BaseModel):
    question: str


class CoachAction(BaseModel):
    type: str
    parameters: dict[str, Any] = Field(
        default_factory=dict
    )


class CoachResponse(BaseModel):
    message: str
    needs_follow_up: bool = False
    follow_up: FollowUp | None = None
    action: CoachAction | None = None
    confirmation_required: bool = False