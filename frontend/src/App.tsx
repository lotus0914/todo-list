import { FormEvent, useEffect, useState } from 'react'

import { createTodo, deleteTodo, fetchTodos, updateTodo } from './lib/api'
import type { Todo } from './types'

type Notice = {
  type: 'success' | 'error'
  message: string
} | null

function App() {
  const [todos, setTodos] = useState<Todo[]>([])
  const [newTitle, setNewTitle] = useState('')
  const [editingId, setEditingId] = useState<number | null>(null)
  const [editingTitle, setEditingTitle] = useState('')
  const [isLoading, setIsLoading] = useState(true)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [notice, setNotice] = useState<Notice>(null)

  async function loadTodos(options?: { silent?: boolean }) {
    if (!options?.silent) {
      setIsLoading(true)
    }

    try {
      const items = await fetchTodos()
      setTodos(items)
    } catch (error) {
      setNotice({
        type: 'error',
        message: error instanceof Error ? error.message : '목록을 불러오지 못했습니다.',
      })
    } finally {
      if (!options?.silent) {
        setIsLoading(false)
      }
    }
  }

  useEffect(() => {
    void loadTodos()
  }, [])

  async function handleCreate(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    const title = newTitle.trim()
    if (!title) {
      setNotice({ type: 'error', message: '할 일 제목을 입력해주세요.' })
      return
    }

    setIsSubmitting(true)
    try {
      await createTodo(title)
      setNewTitle('')
      setNotice({ type: 'success', message: '할 일이 추가되었습니다.' })
      await loadTodos({ silent: true })
    } catch (error) {
      setNotice({
        type: 'error',
        message: error instanceof Error ? error.message : '할 일 추가에 실패했습니다.',
      })
    } finally {
      setIsSubmitting(false)
    }
  }

  async function handleToggle(todo: Todo) {
    setIsSubmitting(true)
    try {
      await updateTodo(todo.id, { is_completed: !todo.is_completed })
      setNotice({ type: 'success', message: '상태가 변경되었습니다.' })
      await loadTodos({ silent: true })
    } catch (error) {
      setNotice({
        type: 'error',
        message: error instanceof Error ? error.message : '상태 변경에 실패했습니다.',
      })
    } finally {
      setIsSubmitting(false)
    }
  }

  function startEdit(todo: Todo) {
    setEditingId(todo.id)
    setEditingTitle(todo.title)
    setNotice(null)
  }

  function cancelEdit() {
    setEditingId(null)
    setEditingTitle('')
  }

  async function saveEdit(todoId: number) {
    const title = editingTitle.trim()
    if (!title) {
      setNotice({ type: 'error', message: '수정할 제목을 입력해주세요.' })
      return
    }

    setIsSubmitting(true)
    try {
      await updateTodo(todoId, { title })
      setEditingId(null)
      setEditingTitle('')
      setNotice({ type: 'success', message: '할 일이 수정되었습니다.' })
      await loadTodos({ silent: true })
    } catch (error) {
      setNotice({
        type: 'error',
        message: error instanceof Error ? error.message : '할 일 수정에 실패했습니다.',
      })
    } finally {
      setIsSubmitting(false)
    }
  }

  async function handleDelete(todoId: number) {
    setIsSubmitting(true)
    try {
      await deleteTodo(todoId)
      if (editingId === todoId) {
        cancelEdit()
      }
      setNotice({ type: 'success', message: '할 일이 삭제되었습니다.' })
      await loadTodos({ silent: true })
    } catch (error) {
      setNotice({
        type: 'error',
        message: error instanceof Error ? error.message : '할 일 삭제에 실패했습니다.',
      })
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <main className="min-h-screen px-2 py-6 sm:px-4">
      <div className="mx-auto max-w-2xl space-y-4">
        <section className="rounded-2xl border border-slate-200 bg-white/90 p-4 shadow-sm backdrop-blur sm:p-6">
          <div className="mb-4 flex items-start justify-between gap-4">
            <div>
              <p className="text-xs font-semibold tracking-[0.18em] text-slate-500">TODO LIST</p>
              <h1 className="mt-1 text-2xl font-semibold text-slate-900">오늘 할 일</h1>
            </div>
            <p className="rounded-full border border-slate-200 bg-slate-50 px-3 py-1 text-xs text-slate-600">
              총 {todos.length}개
            </p>
          </div>

          <form className="flex flex-col gap-2 sm:flex-row" onSubmit={handleCreate}>
            <label className="sr-only" htmlFor="new-todo-input">
              할 일 제목
            </label>
            <input
              id="new-todo-input"
              value={newTitle}
              onChange={(event) => setNewTitle(event.target.value)}
              placeholder="할 일을 입력하세요"
              className="w-full rounded-xl border border-slate-300 bg-white px-3 py-2 text-sm text-slate-900 outline-none ring-0 placeholder:text-slate-400 focus:border-slate-500"
              maxLength={200}
              disabled={isSubmitting}
            />
            <button
              type="submit"
              className="rounded-xl bg-slate-900 px-4 py-2 text-sm font-medium text-white transition hover:bg-slate-700 disabled:cursor-not-allowed disabled:opacity-60"
              disabled={isSubmitting}
            >
              추가
            </button>
          </form>

          {notice ? (
            <p
              role="status"
              className={`mt-3 rounded-lg px-3 py-2 text-sm ${
                notice.type === 'success'
                  ? 'border border-emerald-200 bg-emerald-50 text-emerald-700'
                  : 'border border-rose-200 bg-rose-50 text-rose-700'
              }`}
            >
              {notice.message}
            </p>
          ) : null}
        </section>

        <section className="rounded-2xl border border-slate-200 bg-white/90 p-4 shadow-sm backdrop-blur sm:p-6">
          <div className="mb-3 flex items-center justify-between">
            <h2 className="text-sm font-semibold text-slate-700">목록</h2>
            {isLoading ? <span className="text-xs text-slate-500">불러오는 중...</span> : null}
          </div>

          {isLoading ? (
            <p className="rounded-xl border border-dashed border-slate-200 bg-slate-50 px-3 py-6 text-center text-sm text-slate-500">
              TODO 목록을 불러오는 중입니다.
            </p>
          ) : todos.length === 0 ? (
            <p className="rounded-xl border border-dashed border-slate-200 bg-slate-50 px-3 py-6 text-center text-sm text-slate-500">
              아직 등록된 할 일이 없습니다.
            </p>
          ) : (
            <ul className="space-y-2">
              {todos.map((todo) => {
                const isEditing = editingId === todo.id

                return (
                  <li
                    key={todo.id}
                    className="rounded-xl border border-slate-200 bg-white px-3 py-3"
                    data-testid={`todo-item-${todo.id}`}
                  >
                    <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                      <div className="flex min-w-0 flex-1 items-start gap-3">
                        <button
                          type="button"
                          aria-label={todo.is_completed ? '미완료로 변경' : '완료로 변경'}
                          onClick={() => void handleToggle(todo)}
                          disabled={isSubmitting}
                          className={`mt-0.5 h-5 w-5 shrink-0 rounded-full border transition ${
                            todo.is_completed
                              ? 'border-emerald-600 bg-emerald-600'
                              : 'border-slate-400 bg-white hover:border-slate-600'
                          } disabled:cursor-not-allowed disabled:opacity-60`}
                        />

                        {isEditing ? (
                          <div className="flex w-full flex-col gap-2 sm:flex-row">
                            <input
                              value={editingTitle}
                              onChange={(event) => setEditingTitle(event.target.value)}
                              className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm outline-none focus:border-slate-500"
                              maxLength={200}
                              aria-label="할 일 수정 입력"
                              disabled={isSubmitting}
                            />
                            <div className="flex gap-2">
                              <button
                                type="button"
                                onClick={() => void saveEdit(todo.id)}
                                className="rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-800 hover:bg-slate-50 disabled:opacity-60"
                                disabled={isSubmitting}
                              >
                                저장
                              </button>
                              <button
                                type="button"
                                onClick={cancelEdit}
                                className="rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-600 hover:bg-slate-50 disabled:opacity-60"
                                disabled={isSubmitting}
                              >
                                취소
                              </button>
                            </div>
                          </div>
                        ) : (
                          <div className="min-w-0 flex-1">
                            <p
                              className={`break-words text-sm font-medium ${
                                todo.is_completed ? 'text-slate-400 line-through' : 'text-slate-900'
                              }`}
                            >
                              {todo.title}
                            </p>
                            <p className="mt-1 text-xs text-slate-400">ID {todo.id}</p>
                          </div>
                        )}
                      </div>

                      {!isEditing ? (
                        <div className="flex shrink-0 gap-2 self-end sm:self-center">
                          <button
                            type="button"
                            onClick={() => startEdit(todo)}
                            className="rounded-lg border border-slate-300 px-3 py-2 text-xs font-medium text-slate-700 hover:bg-slate-50 disabled:opacity-60"
                            disabled={isSubmitting}
                          >
                            수정
                          </button>
                          <button
                            type="button"
                            onClick={() => void handleDelete(todo.id)}
                            className="rounded-lg border border-rose-200 px-3 py-2 text-xs font-medium text-rose-700 hover:bg-rose-50 disabled:opacity-60"
                            disabled={isSubmitting}
                          >
                            삭제
                          </button>
                        </div>
                      ) : null}
                    </div>
                  </li>
                )
              })}
            </ul>
          )}
        </section>
      </div>
    </main>
  )
}

export default App
