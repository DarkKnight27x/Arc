import json
import time
from typing import Any

from ai_backend.context.engine import ContextEngine
from ai_backend.context.schemas import CoachContext
from ai_backend.llm.client import LLMClient
from ai_backend.llm.prompts import COACH_SYSTEM_PROMPT
from ai_backend.orchestrator.schemas import (
    FinalResponse,
    OrchestratorResponse,
    ToolResult,
)
from ai_backend.tools.registry import ToolRegistry


MAX_TOOL_ROUNDS = 5


class Orchestrator:
    def __init__(
        self,
        llm_client: LLMClient,
        tool_registry: ToolRegistry,
        context_engine: ContextEngine,
    ) -> None:
        self.llm_client = llm_client
        self.tool_registry = tool_registry
        self.context_engine = context_engine

    def run(
        self,
        user_id: str,
        current_message: str,
        messages: list[dict[str, Any]] | None = None,
        request_context: dict[str, Any] | None = None,
    ) -> OrchestratorResponse:

        request_context = request_context or {}

        conversation_messages = messages or []

        context = self.context_engine.build(
            user_id=user_id,
            current_message=current_message,
            user_data=request_context,
            conversation=conversation_messages,
            available_tools=self.tool_registry.names(),
        )

        conversation = [
            {
                "role": "system",
                "content": COACH_SYSTEM_PROMPT,
            }
        ]

        if conversation_messages:
            conversation.extend(conversation_messages)
        else:
            conversation.append(
                {
                    "role": "user",
                    "content": current_message,
                }
            )

        tool_results: list[ToolResult] = []

        for round_number in range(1, MAX_TOOL_ROUNDS + 1):

            llm_start = time.perf_counter()

            llm_response = self.llm_client.generate(
                messages=conversation,
                tools=self.tool_registry.schemas(),
            )

            llm_duration = time.perf_counter() - llm_start

            print(
                f"[Orchestrator] Round {round_number} "
                f"LLM call: {llm_duration:.2f}s "
                f"-> {llm_response.type}"
            )

            if llm_response.type == "final":
                return OrchestratorResponse(
                    response=FinalResponse(
                        message=llm_response.content or "",
                    ),
                    tool_calls_made=tool_results,
                )

            for tool_call in llm_response.tool_calls:

                tool = self.tool_registry.get(tool_call.name)

                tool_start = time.perf_counter()

                result = tool.execute(
                    user_id=user_id,
                    arguments=tool_call.arguments,
                )

                tool_duration = time.perf_counter() - tool_start

                print(
                    f"[Orchestrator] Round {round_number} "
                    f"Tool call: {tool_duration:.2f}s "
                    f"-> {tool_call.name}"
                )

                tool_result = ToolResult(
                    tool_call_id=tool_call.id,
                    tool_name=tool_call.name,
                    result=result,
                )

                tool_results.append(tool_result)

                self._update_context(
                    context=context,
                    tool_name=tool_call.name,
                    result=result,
                )

                conversation.append(
                    {
                        "role": "assistant",
                        "tool_calls": [
                            {
                                "id": tool_call.id,
                                "type": "function",
                                "function": {
                                    "name": tool_call.name,
                                    "arguments": json.dumps(
                                        tool_call.arguments
                                    ),
                                },
                            }
                        ],
                    }
                )

                conversation.append(
                    {
                        "role": "tool",
                        "tool_call_id": tool_call.id,
                        "content": json.dumps(
                            result,
                            default=str,
                        ),
                    }
                )

        raise RuntimeError(
            f"Maximum tool rounds ({MAX_TOOL_ROUNDS}) exceeded"
        )

    def _update_context(
        self,
        context: CoachContext,
        tool_name: str,
        result: Any,
    ) -> None:
        if tool_name == "get_user_profile":
            context.user.profile = result or {}

        elif tool_name == "get_current_state":
            context.user.current_state = result or {}

        elif tool_name == "get_current_workout":
            if result and result.get("has_workout"):
                context.plans.workout_plan = result.get("plan")

        elif tool_name == "get_current_meal_plan":
            if result and result.get("has_meal_plan"):
                context.plans.meal_plan = result.get("plan")

        elif tool_name == "search_knowledge":
            if result:
                context.knowledge.chunks.extend(result)