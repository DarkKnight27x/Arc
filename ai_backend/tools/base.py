from abc import ABC, abstractmethod
from typing import Any


class Tool(ABC):
    name: str
    description: str

    @abstractmethod
    def execute(
        self,
        user_id: str,
        arguments: dict[str, Any],
    ) -> Any:
        raise NotImplementedError

    @abstractmethod
    def schema(self) -> dict[str, Any]:
        raise NotImplementedError