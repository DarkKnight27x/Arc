from ai_backend.supabase_client import get_supabase_client


def main():
    supabase = get_supabase_client()

    documents = (
        supabase
        .table("knowledge_documents")
        .select("id, title, knowledge_type, source, status")
        .order("created_at", desc=True)
        .limit(5)
        .execute()
    )

    print("\nDocuments:")
    for document in documents.data:
        print(document)

    chunks = (
        supabase
        .table("knowledge_chunks")
        .select(
            "id, document_id, chunk_index, content, "
            "embedding_model, embedding_dimensions"
        )
        .order("created_at", desc=True)
        .limit(5)
        .execute()
    )

    print("\nChunks:")
    for chunk in chunks.data:
        print(chunk)


if __name__ == "__main__":
    main()