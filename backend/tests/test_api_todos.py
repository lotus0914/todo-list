def test_health(client):
    response = client.get("/health")
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "success"
    assert body["data"]["ok"] is True


def test_todo_crud_flow(client):
    create_response = client.post("/api/v1/todos", json={"title": "첫 번째 할 일"})
    assert create_response.status_code == 201
    created = create_response.json()["data"]["item"]
    todo_id = created["id"]
    assert created["title"] == "첫 번째 할 일"
    assert created["is_completed"] is False

    list_response = client.get("/api/v1/todos")
    assert list_response.status_code == 200
    items = list_response.json()["data"]["items"]
    assert len(items) == 1
    assert items[0]["id"] == todo_id

    patch_response = client.patch(f"/api/v1/todos/{todo_id}", json={"title": "수정됨", "is_completed": True})
    assert patch_response.status_code == 200
    patched = patch_response.json()["data"]["item"]
    assert patched["title"] == "수정됨"
    assert patched["is_completed"] is True

    delete_response = client.delete(f"/api/v1/todos/{todo_id}")
    assert delete_response.status_code == 200
    assert delete_response.json()["data"]["deleted_id"] == todo_id

    final_list = client.get("/api/v1/todos")
    assert final_list.status_code == 200
    assert final_list.json()["data"]["items"] == []


def test_validation_error_on_blank_title(client):
    response = client.post("/api/v1/todos", json={"title": "   "})
    assert response.status_code == 422
    body = response.json()
    assert body["status"] == "error"
    assert body["error"]["code"] == "VALIDATION_ERROR"


def test_not_found_on_update(client):
    response = client.patch("/api/v1/todos/999", json={"is_completed": True})
    assert response.status_code == 404
    body = response.json()
    assert body["status"] == "error"
    assert body["error"]["code"] == "HTTP_404"
