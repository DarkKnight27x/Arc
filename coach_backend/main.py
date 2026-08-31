from fastapi import FastAPI
from pydantic import BaseModel

from coach import ask_coach
from context import get_user_context


app = FastAPI(title="Arc Coach API")


class ChatMessage(BaseModel):
    role: str
    content: str


class CoachRequest(BaseModel):
    user_id: str = "demo_user"
    message: str
    conversation: list[ChatMessage] = []


@app.get("/")
def root():
    return {
        "status": "Arc Coach backend is running"
    }


@app.post("/coach/message")
def coach_message(request: CoachRequest):
    context = get_user_context(request.user_id)

    conversation = [
        {
            "role": message.role,
            "content": message.content,
        }
        for message in request.conversation
    ]

    return ask_coach(
        request.message,
        context,
        conversation,
    )