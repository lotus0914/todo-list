from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.todo import Todo


class SqlAlchemyTodoRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def list_todos(self) -> list[Todo]:
        stmt = select(Todo).order_by(Todo.created_at.desc(), Todo.id.desc())
        return list(self.db.execute(stmt).scalars().all())

    def create_todo(self, title: str) -> Todo:
        item = Todo(title=title.strip(), is_completed=False)
        self.db.add(item)
        self.db.commit()
        self.db.refresh(item)
        return item

    def get_todo(self, todo_id: int) -> Todo | None:
        return self.db.get(Todo, todo_id)

    def update_todo(self, todo_id: int, *, title: str | None = None, is_completed: bool | None = None) -> Todo | None:
        item = self.db.get(Todo, todo_id)
        if item is None:
            return None

        if title is not None:
            item.title = title.strip()
        if is_completed is not None:
            item.is_completed = is_completed

        self.db.add(item)
        self.db.commit()
        self.db.refresh(item)
        return item

    def delete_todo(self, todo_id: int) -> bool:
        item = self.db.get(Todo, todo_id)
        if item is None:
            return False
        self.db.delete(item)
        self.db.commit()
        return True
