from ai_backend.llm.router import determine_request


TEST_CASES = [
    # Casual
    ("Hey Arc", "casual"),
    ("Thanks", "casual"),
    ("What's up?", "casual"),

    # Personal data
    ("What's my workout today?", "personal_data"),
    ("What did I eat today?", "personal_data"),
    ("What's my current plan?", "personal_data"),
    ("What am I supposed to eat today?", "personal_data"),

    # Workout knowledge
    ("How do I get stronger?", "workout_knowledge"),
    ("How many sets should I do?", "workout_knowledge"),
    ("Is 3 sets enough?", "workout_knowledge"),
    ("How often should I train?", "workout_knowledge"),
    ("Are low impact workouts effective?", "workout_knowledge"),
    ("What is progressive overload?", "workout_knowledge"),

    # Nutrition knowledge
    ("What are good protein sources?", "nutrition_knowledge"),
    ("How much protein should I eat?", "nutrition_knowledge"),
    ("What are healthy fats?", "nutrition_knowledge"),
    ("What should I eat for fat loss?", "nutrition_knowledge"),

    # General coaching
    ("I missed my workout yesterday", "general_coaching"),
    ("I missed a few workouts", "general_coaching"),
    ("I'm really tired today", "general_coaching"),
    ("I'm getting bored of my workouts", "general_coaching"),
    ("I don't feel like working out", "general_coaching"),
    ("I'm struggling with motivation", "general_coaching"),
    ("I only have 20 minutes today", "general_coaching"),

    # Safety
    ("I feel dizzy during my workout", "safety"),
    ("My chest hurts while exercising", "safety"),
    ("I have sharp pain in my knee", "safety"),
    ("I am having trouble breathing", "safety"),

    # Rehab
    ("I'm recovering from surgery", "rehab"),
    ("Can I train during rehabilitation?", "rehab"),
    ("I need a post-surgery workout", "rehab"),

    # Action detection only
    ("Move Friday's workout to Saturday", "action"),
    ("Change today's workout to 20 minutes", "action"),
    ("Swap my Monday and Wednesday workouts", "action"),
]


def main():
    passed = 0

    for message, expected in TEST_CASES:
        result = determine_request(message)
        actual = result.query_class.value

        if actual == expected:
            print(f"PASS | {message}")
            passed += 1
        else:
            print(
                f"FAIL | {message}\n"
                f"      expected: {expected}\n"
                f"      actual:   {actual}\n"
            )

    print()
    print(f"{passed}/{len(TEST_CASES)} tests passed")


if __name__ == "__main__":
    main()