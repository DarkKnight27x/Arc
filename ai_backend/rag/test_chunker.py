from ai_backend.rag.chunker import chunk_document
from ai_backend.rag.documents import load_text_document


def main():
    document = load_text_document(
        "test_knowledge.txt",
        title="Test Knowledge",
        knowledge_type="general",
    )

    chunks = chunk_document(
        document,
        max_words=10,
        overlap_words=2,
    )

    print(f"Created {len(chunks)} chunks")

    for chunk in chunks:
        print()
        print(f"Chunk {chunk.chunk_index}:")
        print(chunk.content)


if __name__ == "__main__":
    main()