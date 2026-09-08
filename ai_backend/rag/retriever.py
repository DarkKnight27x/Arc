from ai_backend.rag.embeddings import embed_text
from ai_backend.supabase_client import get_supabase_client


EMBEDDING_MODEL = "BAAI/bge-small-en-v1.5"


def retrieve_knowledge(
    query: str,
    match_count: int = 5,
    knowledge_type: str | None = None,
    metadata_filter: dict | None = None,
) -> list[dict]:
    if not query.strip():
        raise ValueError("Query cannot be empty")

    supabase = get_supabase_client()

    query_embedding = embed_text(query)

    filters = dict(metadata_filter or {})

    if knowledge_type is not None:
        filters["knowledge_type"] = knowledge_type

    response = supabase.rpc(
        "match_knowledge_chunks",
        {
            "query_embedding": query_embedding,
            "query_embedding_model": EMBEDDING_MODEL,
            "match_count": match_count,
            "metadata_filter": filters,
        },
    ).execute()

    return response.data