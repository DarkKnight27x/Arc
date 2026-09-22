from fastapi import FastAPI

from ai_backend.api.schemas import CoachRequest, CoachResponse
from ai_backend.context.engine import ContextEngine
from ai_backend.llm.client import LLMClient
from ai_backend.orchestrator.engine import Orchestrator
from ai_backend.tools.bootstrap import create_tool_registry


app = FastAPI(title="Arc AI Backend")


tool_registry = create_tool_registry()
context_engine = ContextEngine()
llm_client = LLMClient()

orchestrator = Orchestrator(
    llm_client=llm_client,
    tool_registry=tool_registry,
    context_engine=context_engine,
)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/coach/message", response_model=CoachResponse)
def coach_message(request: CoachRequest):
    result = orchestrator.run(
        user_id=request.user_id,
        current_message=request.message,
        messages=[
            message.model_dump()
            for message in request.conversation
        ],
    )

    return CoachResponse(
        message=result.response.message,
        needs_follow_up=result.response.needs_follow_up,
        follow_up=(
            {
                "question": result.response.follow_up_question
            }
            if result.response.follow_up_question
            else None
        ),
    )