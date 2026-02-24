from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.exceptions import InvalidTodoUpdateError, TodoNotFoundError
from app.core.responses import success_response
from app.db.session import get_db
from app.repositories.sqlalchemy_todo_repository import SqlAlchemyTodoRepository
from app.schemas.todo import TodoCreate, TodoRead, TodoUpdate
from app.services.todo_service import TodoService

router = APIRouter()


def get_todo_service(db: Session = Depends(get_db)) -> TodoService:
    repo = SqlAlchemyTodoRepository(db)
    return TodoService(repo)


@router.get("")
def list_todos(service: TodoService = Depends(get_todo_service)):
    items = [TodoRead.model_validate(todo).model_dump(mode="json") for todo in service.list_todos()]
    return success_response({"items": items})


@router.post("", status_code=status.HTTP_201_CREATED)
def create_todo(payload: TodoCreate, service: TodoService = Depends(get_todo_service)):
    item = service.create_todo(payload.title)
    return success_response({"item": TodoRead.model_validate(item).model_dump(mode="json")})


@router.patch("/{todo_id}")
def update_todo(todo_id: int, payload: TodoUpdate, service: TodoService = Depends(get_todo_service)):
    try:
        item = service.update_todo(todo_id, title=payload.title, is_completed=payload.is_completed)
    except TodoNotFoundError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except InvalidTodoUpdateError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    return success_response({"item": TodoRead.model_validate(item).model_dump(mode="json")})


@router.delete("/{todo_id}")
def delete_todo(todo_id: int, service: TodoService = Depends(get_todo_service)):
    try:
        service.delete_todo(todo_id)
    except TodoNotFoundError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    return success_response({"deleted_id": todo_id})
