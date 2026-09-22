from ai_backend.rag.ingest import ingest_document


DOCUMENTS = [
    {
        "path": "ai_backend/rag/knowledge/workout_guidance.txt",
        "title": "Workout Guidance",
        "knowledge_type": "workout_guidance",
    },
    {
        "path": "ai_backend/rag/knowledge/nutrition_guidance.txt",
        "title": "Nutrition Guidance",
        "knowledge_type": "nutrition_guidance",
    },
    {
        "path": "ai_backend/rag/knowledge/safety_guidance.txt",
        "title": "Safety Guidance",
        "knowledge_type": "safety_guidance",
    },
    {
        "path": "ai_backend/rag/knowledge/general_coaching.txt",
        "title": "General Coaching",
        "knowledge_type": "general_coaching",
    },
    {
        "path": "ai_backend/rag/knowledge/rehab_guidance.txt",
        "title": "Rehab Guidance",
        "knowledge_type": "rehab_guidance",
    },
]


def main():
    for document in DOCUMENTS:
        print(f"\nIngesting: {document['title']}")

        ingest_document(
            path=document["path"],
            title=document["title"],
            knowledge_type=document["knowledge_type"],
        )


if __name__ == "__main__":
    main()