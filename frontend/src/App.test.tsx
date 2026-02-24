import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import App from './App'

type Todo = {
  id: number
  title: string
  is_completed: boolean
  created_at: string
  updated_at: string
}

function envelope(data: unknown, ok = true) {
  return {
    ok,
    status: ok ? 200 : 400,
    json: async () => ({
      status: ok ? 'success' : 'error',
      data: ok ? data : null,
      error: ok ? null : { code: 'ERR', message: '실패', details: null },
      metadata: { timestamp: new Date().toISOString() },
    }),
  }
}

describe('App', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('초기 빈 상태를 렌더링한다', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => envelope({ items: [] })))

    render(<App />)

    expect(screen.getByText('TODO 목록을 불러오는 중입니다.')).toBeInTheDocument()
    expect(await screen.findByText('아직 등록된 할 일이 없습니다.')).toBeInTheDocument()
  })

  it('추가/토글/수정/삭제 흐름이 동작한다', async () => {
    const user = userEvent.setup()
    let items: Todo[] = []
    let seq = 1

    const fetchMock = vi.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
      const url = String(input)
      const method = init?.method ?? 'GET'
      const bodyText = typeof init?.body === 'string' ? init.body : undefined
      const body = bodyText ? (JSON.parse(bodyText) as Record<string, unknown>) : undefined

      if (url.endsWith('/todos') && method === 'GET') {
        return envelope({ items })
      }

      if (url.endsWith('/todos') && method === 'POST') {
        const now = new Date().toISOString()
        const title = String(body?.title ?? '')
        const item: Todo = {
          id: seq++,
          title,
          is_completed: false,
          created_at: now,
          updated_at: now,
        }
        items = [item, ...items]
        return { ...envelope({ item }), status: 201 }
      }

      const match = url.match(/\/todos\/(\d+)$/)
      if (!match) {
        return envelope({ items })
      }

      const todoId = Number(match[1])
      const target = items.find((item) => item.id === todoId)
      if (!target) {
        return {
          ok: false,
          status: 404,
          json: async () => ({
            status: 'error',
            data: null,
            error: { code: 'HTTP_404', message: 'TODO를 찾을 수 없습니다.', details: null },
            metadata: { timestamp: new Date().toISOString() },
          }),
        }
      }

      if (method === 'PATCH') {
        const updated: Todo = {
          ...target,
          title: typeof body?.title === 'string' ? body.title : target.title,
          is_completed:
            typeof body?.is_completed === 'boolean' ? body.is_completed : target.is_completed,
          updated_at: new Date().toISOString(),
        }
        items = items.map((item) => (item.id === todoId ? updated : item))
        return envelope({ item: updated })
      }

      if (method === 'DELETE') {
        items = items.filter((item) => item.id !== todoId)
        return envelope({ deleted_id: todoId })
      }

      return envelope({ items })
    })

    vi.stubGlobal('fetch', fetchMock)

    render(<App />)

    await screen.findByText('아직 등록된 할 일이 없습니다.')

    await user.type(screen.getByLabelText('할 일 제목'), '문서 작성')
    await user.click(screen.getByRole('button', { name: '추가' }))

    expect(await screen.findByText('문서 작성')).toBeInTheDocument()
    expect(screen.getByText('할 일이 추가되었습니다.')).toBeInTheDocument()

    await user.click(screen.getByLabelText('완료로 변경'))
    await waitFor(() => expect(screen.getByText('상태가 변경되었습니다.')).toBeInTheDocument())

    await user.click(screen.getByRole('button', { name: '수정' }))
    const editInput = screen.getByLabelText('할 일 수정 입력')
    await user.clear(editInput)
    await user.type(editInput, '문서 작성 완료')
    await user.click(screen.getByRole('button', { name: '저장' }))

    expect(await screen.findByText('문서 작성 완료')).toBeInTheDocument()

    await user.click(screen.getByRole('button', { name: '삭제' }))
    expect(await screen.findByText('아직 등록된 할 일이 없습니다.')).toBeInTheDocument()

    expect(fetchMock).toHaveBeenCalled()
  })

  it('API 실패 메시지를 표시한다', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(async () => ({
        ok: false,
        status: 500,
        json: async () => ({
          status: 'error',
          data: null,
          error: { code: 'HTTP_500', message: '서버 오류', details: null },
          metadata: { timestamp: new Date().toISOString() },
        }),
      })),
    )

    render(<App />)

    expect(await screen.findByText('서버 오류')).toBeInTheDocument()
  })
})
