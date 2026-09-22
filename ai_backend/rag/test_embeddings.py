from ai_backend.rag.embeddings import embed_text


def main():
    text = "Low impact strength training for beginners."

    embedding = embed_text(text)

    print("Embedding generated")
    print("Dimensions:", len(embedding))
    print("First 5 values:", embedding[:5])


if __name__ == "__main__":
    main()