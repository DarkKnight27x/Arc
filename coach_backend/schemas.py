from typing import Any, Optional

from pydantic import BaseModel, Field


class CoachAction(BaseModel):
    type: str
    parameters: dict[str, Any] = Field(default_factory=dict)


class FollowUp(BaseModel):
    question: str


class CoachResponse(BaseModel):
    message: str
    needs_follow_up: bool
    follow_up: Optional[FollowUp] = None
    action: Optional[CoachAction] = None
    confirmation_required: bool = False