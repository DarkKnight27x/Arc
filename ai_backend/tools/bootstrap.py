from ai_backend.tools.get_current_state import GetCurrentStateTool
from ai_backend.tools.get_current_workout import GetCurrentWorkoutTool
from ai_backend.tools.get_user_profile import GetUserProfileTool
from ai_backend.tools.registry import ToolRegistry
from ai_backend.tools.search_knowledge import SearchKnowledgeTool


def create_tool_registry() -> ToolRegistry:
    registry = ToolRegistry()

    registry.register(SearchKnowledgeTool())
    registry.register(GetUserProfileTool())
    registry.register(GetCurrentStateTool())
    registry.register(GetCurrentWorkoutTool())

    return registry