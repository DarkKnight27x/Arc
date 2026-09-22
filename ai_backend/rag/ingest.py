from ai_backend.rag.chunker import chunk_document
from ai_backend.rag.documents import load_text_document
from ai_backend.rag.embeddings import embed_texts
from ai_backend.supabase_client import get_supabase_client


EMBEDDING_MODEL = "BAAI/bge-small-en-v1.5"


def ingest_document(
    path: str,
    title: str,
    knowledge_type: str,
) -> None:
    supabase = get_supabase_client()

    # 1. Load document
    document = load_text_document(
        path=path,
        title=title,
        knowledge_type=knowledge_type,
    )

    # 2. Split document into chunks
    chunks = chunk_document(document)

    if not chunks:
        raise ValueError("Document produced no chunks")

    # 3. Generate embeddings
    embeddings = embed_texts(
        [chunk.content for chunk in chunks]
    )

    if len(embeddings) != len(chunks):
        raise RuntimeError(
            "Number of embeddings does not match number of chunks"
        )

    # 4. Remove existing version of this document
    existing_response = (
        supabase
        .table("knowledge_documents")
        .select("id")
        .eq("title", document.title)
        .eq("knowledge_type", document.knowledge_type)
        .execute()
    )

    for existing_document in existing_response.data:
        (
            supabase
            .table("knowledge_documents")
            .delete()
            .eq("id", existing_document["id"])
            .execute()
        )

    # 5. Insert parent document
    document_response = (
        supabase
        .table("knowledge_documents")
        .insert({
            "title": document.title,
            "knowledge_type": document.knowledge_type,
            "source": document.source,
            "status": "published",
        })
        .execute()
    )

    if not document_response.data:
        raise RuntimeError(
            "Failed to insert knowledge document"
        )

    document_id = document_response.data[0]["id"]

    # 6. Prepare chunk rows
    chunk_rows = []

    for chunk, embedding in zip(chunks, embeddings):
        chunk_rows.append({
            "document_id": document_id,
            "chunk_index": chunk.chunk_index,
            "content": chunk.content,

            # Metadata used for filtered retrieval
            "metadata": {
                "knowledge_type": document.knowledge_type,
                "document_title": document.title,
            },

            "embedding": embedding,
            "embedding_model": EMBEDDING_MODEL,
            "embedding_dimensions": len(embedding),
        })

    # 7. Insert chunks
    chunk_response = (
        supabase
        .table("knowledge_chunks")
        .insert(chunk_rows)
        .execute()
    )

    if not chunk_response.data:
        raise RuntimeError(
            "Failed to insert knowledge chunks"
        )

    print(f"Document inserted: {document_id}")
    print(f"Chunks inserted: {len(chunk_response.data)}")