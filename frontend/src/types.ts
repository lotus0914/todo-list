export type Todo = {
  id: number
  title: string
  is_completed: boolean
  created_at: string
  updated_at: string
}

export type ApiEnvelope<T> = {
  status: 'success' | 'error'
  data: T | null
  error: {
    code: string
    message: string
    details?: unknown
  } | null
  metadata: {
    timestamp: string
  }
}
