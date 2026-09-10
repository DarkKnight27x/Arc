from enum import Enum
from typing import Optional

from pydantic import BaseModel


class QueryClass(str, Enum):
    CASUAL = "casual"
    PERSONAL_DATA = "personal_data"
    WORKOUT_KNOWLEDGE = "workout_knowledge"
    NUTRITION_KNOWLEDGE = "nutrition_knowledge"
    GENERAL_COACHING = "general_coaching"
    SAFETY = "safety"
    REHAB = "rehab"
    ACTION = "action"


class KnowledgeType(str, Enum):
    WORKOUT_GUIDANCE = "workout_guidance"
    NUTRITION_GUIDANCE = "nutrition_guidance"
    SAFETY_GUIDANCE = "safety_guidance"
    REHAB_GUIDANCE = "rehab_guidance"
    GENERAL_COACHING = "general_coaching"


class DeterminationResult(BaseModel):
    query_class: QueryClass

    needs_rag: bool = False
    knowledge_type: Optional[KnowledgeType] = None

    needs_supabase: bool = False

    action_required: bool = False
    action: Optional[str] = None