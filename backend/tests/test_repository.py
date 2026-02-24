from app.repositories.sqlalchemy_todo_repository import SqlAlchemyTodoRepository


def test_repository_crud(db_session):
    repo = SqlAlchemyTodoRepository(db_session)

    created = repo.create_todo("할 일 1")
    assert created.id is not None
    assert created.title == "할 일 1"
    assert created.is_completed is False

    items = repo.list_todos()
    assert len(items) == 1
    assert items[0].id == created.id

    updated = repo.update_todo(created.id, title="할 일 수정", is_completed=True)
    assert updated is not None
    assert updated.title == "할 일 수정"
    assert updated.is_completed is True

    fetched = repo.get_todo(created.id)
    assert fetched is not None
    assert fetched.title == "할 일 수정"

    assert repo.delete_todo(created.id) is True
    assert repo.get_todo(created.id) is None
    assert repo.delete_todo(created.id) is False
