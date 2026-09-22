from ai_backend.supabase_client import get_supabase_client


def main():
    supabase = get_supabase_client()

    response = (
        supabase
        .table("knowledge_documents")
        .select("id")
        .limit(1)
        .execute()
    )

    print("Supabase connection OK")
    print(response.data)


if __name__ == "__main__":
    main()