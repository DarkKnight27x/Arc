from ai_backend.rag.retriever import retrieve_knowledge


TEST_QUERIES = [
    (
        "What is progressive overload?",
        "workout_guidance",
    ),
    (
        "Does low impact mean the workout is easy?",
        "workout_guidance",
    ),
    (
        "What should a balanced Indian meal contain?",
        "nutrition_guidance",
    ),
    (
        "What are good protein sources for an eggetarian?",
        "nutrition_guidance",
    ),
    (
        "What should I do if I feel dizzy during a workout?",
        "safety_guidance",
    ),
    (
        "What should I do if I have chest pain while exercising?",
        "safety_guidance",
    ),
    (
        "How should I handle a low-energy day?",
        "general_coaching",
    ),
    (
        "What should I do if I miss a workout?",
        "general_coaching",
    ),
    (
        "Can Arc create a post-surgery rehabilitation program?",
        "rehab_guidance",
    ),
]


def main():
    for query, expected_type in TEST_QUERIES:
        results = retrieve_knowledge(
            query=query,
            match_count=3,
            knowledge_type=expected_type,
        )

        print("\n" + "=" * 70)
        print(f"QUERY: {query}")
        print(f"EXPECTED TYPE: {expected_type}")

        for i, result in enumerate(results, start=1):
            print(f"\n--- Result {i} ---")
            print(f"Similarity: {result['similarity']:.4f}")
            print(f"Content: {result['content'][:500]}")


if __name__ == "__main__":
    main()