from dataclasses import dataclass
from pathlib import Path


@dataclass
class KnowledgeDocument:
    title: str
    knowledge_type: str
    source: str
    content: str


def load_text_document(
    path: str | Path,
    title: str,
    knowledge_type: str,
) -> KnowledgeDocument:
    path = Path(path)

    if not path.exists():
        raise FileNotFoundError(f"Knowledge file not found: {path}")

    content = path.read_text(encoding="utf-8")

    if not content.strip():
        raise ValueError(f"Knowledge file is empty: {path}")

    return KnowledgeDocument(
        title=title,
        knowledge_type=knowledge_type,
        source=str(path),
        content=content,
    )