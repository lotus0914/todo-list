from __future__ import annotations

from app.core.exceptions import InvalidTodoUpdateError, TodoNotFoundError
from app.models.todo import Todo
from app.repositories.interfaces import TodoRepository


class TodoService:
    def __init__(self, repository: TodoRepository) -> None:
        self.repository = repository

    def list_todos(self) -> list[Todo]:
        return self.repository.list_todos()

    def create_todo(self, title: str) -> Todo:
        cleaned = title.strip()
        if not cleaned:
            raise ValueError("제목은 비어 있을 수 없습니다.")
        if len(cleaned) > 200:
            raise ValueError("제목은 200자를 초과할 수 없습니다.")
        return self.repository.create_todo(cleaned)

    def update_todo(self, todo_id: int, *, title: str | None = None, is_completed: bool | None = None) -> Todo:
        if title is None and is_completed is None:
            raise InvalidTodoUpdateError("수정할 필드가 필요합니다.")

        if title is not None:
            title = title.strip()
            if not title:
                raise ValueError("제목은 비어 있을 수 없습니다.")
            if len(title) > 200:
                raise ValueError("제목은 200자를 초과할 수 없습니다.")

        item = self.repository.update_todo(todo_id, title=title, is_completed=is_completed)
        if item is None:
            raise TodoNotFoundError("TODO를 찾을 수 없습니다.")
        return item

    def delete_todo(self, todo_id: int) -> None:
        deleted = self.repository.delete_todo(todo_id)
        if not deleted:
            raise TodoNotFoundError("TODO를 찾을 수 없습니다.")
