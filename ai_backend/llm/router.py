import re

from ai_backend.llm.schemas import (
    DeterminationResult,
    KnowledgeType,
    QueryClass,
)


def normalize_message(message: str) -> str:
    return re.sub(r"\s+", " ", message.lower().strip())


def contains_any(message: str, phrases: tuple[str, ...]) -> bool:
    return any(phrase in message for phrase in phrases)


# ---------------------------------------------------------------------------
# Safety
# ---------------------------------------------------------------------------

def is_safety_related(message: str) -> bool:
    safety_terms = (
        "dizzy",
        "dizziness",
        "faint",
        "fainted",
        "fainting",
        "feel like i'm going to faint",
        "feel like i am going to faint",
        "chest pain",
        "chest hurts",
        "can't breathe",
        "cannot breathe",
        "trouble breathing",
        "difficulty breathing",
        "shortness of breath",
        "severe pain",
        "sharp pain",
        "pain",
        "hurts",
        "hurt",
        "injury",
        "injured",
        "bleeding",
        "pulled something",
        "strained something",
        "swelling",
        "swollen",
    )

    return contains_any(message, safety_terms)


# ---------------------------------------------------------------------------
# Rehabilitation
# ---------------------------------------------------------------------------

def is_rehab_related(message: str) -> bool:
    rehab_terms = (
        "rehabilitation",
        "rehab",
        "post-surgery",
        "post surgery",
        "after surgery",
        "surgery recovery",
        "recovering from surgery",
        "just had surgery",
        "had surgery",
        "recent surgery",
        "recently had surgery",
    )

    return contains_any(message, rehab_terms)


# ---------------------------------------------------------------------------
# Action detection
# ---------------------------------------------------------------------------

def detect_action(message: str) -> str | None:
    action_patterns = {
        "move_workout": (
            "move my workout",
            "move today's workout",
            "move todays workout",
            "move friday's workout",
            "move fridays workout",
            "move my friday workout",
            "move my workout to",
        ),
        "swap_workout": (
            "swap my workouts",
            "swap my workout",
            "swap workout days",
            "switch my workouts",
            "switch my workout days",
            "swap my monday and wednesday workouts",
            "swap monday and wednesday workouts",
            "switch my monday and wednesday workouts",
            "switch monday and wednesday workouts",
        ),
        "modify_workout": (
            "change my workout",
            "change today's workout",
            "change todays workout",
            "modify my workout",
            "adjust my workout",
            "make today's workout",
            "make todays workout",
        ),
        "mark_workout_completed": (
            "mark my workout completed",
            "mark today's workout completed",
            "mark todays workout completed",
            "mark workout as completed",
            "log my workout",
        ),
    }

    for action, phrases in action_patterns.items():
        if contains_any(message, phrases):
            return action

    return None


# ---------------------------------------------------------------------------
# Personal data
# ---------------------------------------------------------------------------

def personal_data_score(message: str) -> int:
    score = 0

    personal_phrases = (
        "my workout",
        "my plan",
        "my meal",
        "my meals",
        "my progress",
        "my streak",
        "my calories",
        "my protein",
        "my schedule",
        "current plan",
        "last workout",
        "previous workout",
        "today's workout",
        "todays workout",
        "today's meal",
        "todays meal",
        "what did i eat",
        "what did i do",
        "what am i doing",
        "what do i have",
        "what am i supposed to eat",
    )

    for phrase in personal_phrases:
        if phrase in message:
            score += 3

    personal_question_phrases = (
        "how many calories did i eat",
        "how much protein did i get",
        "what exercises am i doing",
        "what am i training",
        "what do i have planned",
        "what's on my schedule",
        "whats on my schedule",
    )

    for phrase in personal_question_phrases:
        if phrase in message:
            score += 4

    return score


# ---------------------------------------------------------------------------
# Workout knowledge
# ---------------------------------------------------------------------------

def workout_knowledge_score(message: str) -> int:
    score = 0

    strong_signals = (
        "progressive overload",
        "training volume",
        "sets and reps",
        "sets and repetitions",
        "rest between sets",
        "training frequency",
        "strength training",
        "exercise technique",
        "workout recovery",
        "increase my weights",
        "increase the weight",
        "more reps",
        "more weight",
    )

    for phrase in strong_signals:
        if phrase in message:
            score += 4

    general_signals = (
    "get stronger",
    "how do i get stronger",
    "make my workouts harder",
    "make my workout harder",
    "how many sets",
    "how many sets should i do",
    "sets enough",
    "is 3 sets enough",
    "how many reps",
    "how often should i train",
    "how often should i work out",
    "how often should i workout",
    "how often should",
    "recover after a workout",
    "recover after a hard workout",
    "harder workout",
    "training",
    "workout",
    "exercise",
    "weights",
    "strength",
    "low impact",
    "low-impact",
)

    for phrase in general_signals:
        if phrase in message:
            score += 2

    return score


# ---------------------------------------------------------------------------
# Nutrition knowledge
# ---------------------------------------------------------------------------

def nutrition_knowledge_score(message: str) -> int:
    score = 0

    strong_signals = (
        "protein",
        "protein sources",
        "balanced meal",
        "balanced diet",
        "indian meal",
        "eggetarian",
        "carbohydrates",
        "carbs",
        "dietary fat",
        "healthy fats",
        "fat loss nutrition",
        "lose fat",
        "losing fat",
        "high protein",
        "more protein",
    )

    for phrase in strong_signals:
        if phrase in message:
            score += 4

    general_signals = (
        "what should i eat",
        "what can i eat",
        "how should i eat",
        "food",
        "meal",
        "diet",
        "eat",
        "calories",
    )

    for phrase in general_signals:
        if phrase in message:
            score += 2

    return score


# ---------------------------------------------------------------------------
# General coaching
# ---------------------------------------------------------------------------

def general_coaching_score(message: str) -> int:
    score = 0

    coaching_signals = (
        "missed my workout",
        "missed a workout",
        "missed a few workouts",
        "missed a few sessions",
        "missed several workouts",
        "missed several sessions",
        "missed yesterday",
        "skipped the gym",
        "skipped my workout",
        "skipped today",
        "don't feel like working out",
        "dont feel like working out",
        "don't feel like going to the gym",
        "dont feel like going to the gym",
        "really tired",
        "no energy",
        "low energy",
        "barely slept",
        "didn't sleep well",
        "didnt sleep well",
        "trouble staying consistent",
        "struggling with motivation",
        "motivation",
        "consistency",
        "stressed",
        "stress",
        "plateau",
        "not seeing progress",
        "getting bored",
        "bored of my workouts",
        "routine",
        "dead today",
        "exhausted",
        "running late",
        "only have 20 minutes",
        "only have 30 minutes",
    )

    for phrase in coaching_signals:
        if phrase in message:
            score += 3

    return score


# ---------------------------------------------------------------------------
# Main determination engine
# ---------------------------------------------------------------------------

def determine_request(message: str) -> DeterminationResult:
    if not message.strip():
        raise ValueError("Message cannot be empty")

    message = normalize_message(message)

    # 1. Safety always takes priority.
    if is_safety_related(message):
        return DeterminationResult(
            query_class=QueryClass.SAFETY,
            needs_rag=True,
            knowledge_type=KnowledgeType.SAFETY_GUIDANCE,
        )

    # 2. Rehabilitation boundary.
    if is_rehab_related(message):
        return DeterminationResult(
            query_class=QueryClass.REHAB,
            needs_rag=True,
            knowledge_type=KnowledgeType.REHAB_GUIDANCE,
        )

    # 3. Explicit action detection.
    # Actions are detected only.
    # No Supabase read/write is performed at this stage.
    action = detect_action(message)

    if action is not None:
        return DeterminationResult(
            query_class=QueryClass.ACTION,
            needs_supabase=True,
            action_required=True,
            action=action,
        )

    # 4. Calculate intent scores.
    personal_score = personal_data_score(message)
    workout_score = workout_knowledge_score(message)
    nutrition_score = nutrition_knowledge_score(message)
    coaching_score = general_coaching_score(message)

    # 5. Strong personal-data request.
    #
    # Coaching takes priority over generic personal phrases such as
    # "my workout" when the user is clearly asking for advice.
    if personal_score >= 3 and coaching_score < 3:
        return DeterminationResult(
            query_class=QueryClass.PERSONAL_DATA,
            needs_supabase=True,
        )

    # 6. Determine strongest knowledge class.
    knowledge_scores = {
        QueryClass.WORKOUT_KNOWLEDGE: workout_score,
        QueryClass.NUTRITION_KNOWLEDGE: nutrition_score,
        QueryClass.GENERAL_COACHING: coaching_score,
    }

    best_class = max(
        knowledge_scores,
        key=knowledge_scores.get,
    )

    best_score = knowledge_scores[best_class]

    if best_score >= 3:
        knowledge_type_map = {
            QueryClass.WORKOUT_KNOWLEDGE: KnowledgeType.WORKOUT_GUIDANCE,
            QueryClass.NUTRITION_KNOWLEDGE: KnowledgeType.NUTRITION_GUIDANCE,
            QueryClass.GENERAL_COACHING: KnowledgeType.GENERAL_COACHING,
        }

        return DeterminationResult(
            query_class=best_class,
            needs_rag=True,
            knowledge_type=knowledge_type_map[best_class],
        )

    # 7. Nothing external is required.
    return DeterminationResult(
        query_class=QueryClass.CASUAL,
    )