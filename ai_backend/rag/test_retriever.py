from ai_backend.rag.retriever import retrieve_knowledge


def main():
    query = "What is low impact strength training?"

    results = retrieve_knowledge(
        query=query,
        match_count=5,
    )

    print(f"\nQuery: {query}")
    print(f"Retrieved {len(results)} chunks:\n")

    for i, result in enumerate(results, start=1):
        print(f"--- Result {i} ---")
        print(f"Chunk ID: {result['chunk_id']}")
        print(f"Document ID: {result['document_id']}")
        print(f"Similarity: {result['similarity']}")
        print(f"Content: {result['content']}")
        print()


if __name__ == "__main__":
    main()