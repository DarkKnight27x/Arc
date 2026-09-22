from ai_backend.rag.documents import load_text_document


def main():
    document = load_text_document(
        "test_knowledge.txt",
        title="Test Knowledge",
        knowledge_type="general",
    )

    print("Title:", document.title)
    print("Type:", document.knowledge_type)
    print("Source:", document.source)
    print("Content:", document.content)


if __name__ == "__main__":
    main()