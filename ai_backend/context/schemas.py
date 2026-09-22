from typing import Any

from pydantic import BaseModel, Field


class UserState(BaseModel):
    profile: dict[str, Any] = Field(default_factory=dict)
    goals: dict[str, Any] = Field(default_factory=dict)
    preferences: dict[str, Any] = Field(default_factory=dict)
    current_state: dict[str, Any] = Field(default_factory=dict)


class PlanState(BaseModel):
    workout_plan: dict[str, Any] | None = None
    meal_plan: dict[str, Any] | None = None


class ActivityState(BaseModel):
    recent_workouts: list[dict[str, Any]] = Field(default_factory=list)
    recent_meals: list[dict[str, Any]] = Field(default_factory=list)
    progress: dict[str, Any] = Field(default_factory=dict)


class ConversationState(BaseModel):
    messages: list[dict[str, str]] = Field(default_factory=list)


class KnowledgeContext(BaseModel):
    chunks: list[dict[str, Any]] = Field(default_factory=list)


class SafetyContext(BaseModel):
    restrictions: list[str] = Field(default_factory=list)
    flags: list[str] = Field(default_factory=list)


class CoachContext(BaseModel):
    user_id: str
    current_message: str

    user: UserState = Field(default_factory=UserState)
    plans: PlanState = Field(default_factory=PlanState)
    activity: ActivityState = Field(default_factory=ActivityState)
    conversation: ConversationState = Field(
        default_factory=ConversationState
    )
    knowledge: KnowledgeContext = Field(
        default_factory=KnowledgeContext
    )
    safety: SafetyContext = Field(default_factory=SafetyContext)

    available_tools: list[str] = Field(default_factory=list)