from ai_backend.supabase_client import get_supabase_client


def main():
    supabase = get_supabase_client()

    response = (
        supabase
        .table("knowledge_documents")
        .select("id, title, knowledge_type")
        .eq("title", "Test Knowledge")
        .eq("knowledge_type", "general_coaching")
        .execute()
    )

    for document in response.data:
        supabase \
            .table("knowledge_documents") \
            .delete() \
            .eq("id", document["id"]) \
            .execute()

        print(f"Deleted test document: {document['id']}")


if __name__ == "__main__":
    main()