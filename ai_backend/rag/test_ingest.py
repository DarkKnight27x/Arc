from ai_backend.rag.ingest import ingest_document

def main():
    ingest_document(
        path="test_knowledge.txt",
        title="Test Knowledge",
        knowledge_type="general_coaching",
    )

if __name__ == "__main__":
    main()