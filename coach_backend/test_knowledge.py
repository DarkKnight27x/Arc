from knowledge import get_relevant_knowledge


test_messages = [
    "I want a core workout",
    "I want British food",
    "I'm travelling tomorrow",
    "My knee is swollen",
]


for message in test_messages:
    print("\nMESSAGE:", message)
    print(get_relevant_knowledge(message))