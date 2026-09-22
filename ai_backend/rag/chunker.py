from dataclasses import dataclass

from ai_backend.rag.documents import KnowledgeDocument


@dataclass
class KnowledgeChunk:
    document_title: str
    knowledge_type: str
    source: str
    chunk_index: int
    content: str


def _split_large_section(
    text: str,
    max_words: int,
    overlap_words: int,
) -> list[str]:
    words = text.split()

    if len(words) <= max_words:
        return [text.strip()]

    chunks = []
    start = 0

    while start < len(words):
        end = min(start + max_words, len(words))
        chunk = " ".join(words[start:end]).strip()

        if chunk:
            chunks.append(chunk)

        if end == len(words):
            break

        start = end - overlap_words

    return chunks


def chunk_document(
    document: KnowledgeDocument,
    max_words: int = 300,
    overlap_words: int = 40,
) -> list[KnowledgeChunk]:
    if not document.content.strip():
        return []

    if overlap_words >= max_words:
        raise ValueError("overlap_words must be smaller than max_words")

    lines = document.content.splitlines()

    # The first non-empty line is the document title.
    # It should not become a knowledge chunk by itself.
    first_content_line = next(
        (line.strip() for line in lines if line.strip()),
        None,
    )

    if first_content_line is None:
        return []

    title_index = next(
        i for i, line in enumerate(lines)
        if line.strip()
    )

    lines = lines[title_index + 1:]

    sections = []
    current_section = []

    for line in lines:
        line = line.strip()

        if not line:
            continue

        if (
            current_section
            and len(line.split()) <= 8
            and not line.endswith(".")
        ):
            sections.append("\n".join(current_section))
            current_section = [line]
        else:
            current_section.append(line)

    if current_section:
        sections.append("\n".join(current_section))

    chunks = []
    chunk_index = 0

    for section in sections:
        section_chunks = _split_large_section(
            section,
            max_words=max_words,
            overlap_words=overlap_words,
        )

        for content in section_chunks:
            chunks.append(
                KnowledgeChunk(
                    document_title=document.title,
                    knowledge_type=document.knowledge_type,
                    source=document.source,
                    chunk_index=chunk_index,
                    content=content,
                )
            )
            chunk_index += 1

    return chunks