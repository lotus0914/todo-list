# Todo List MVP - Technical Specification (SPEC.md)

> **이 문서의 용도**: 프로젝트 초기 구현 시 참고하는 설계 청사진입니다.  
> 구현 완료 후에는 코드와 테스트가 Source of Truth입니다.
>
> **참고**: 이 프로젝트는 React + FastAPI 풀스택 구조 학습 및 실전 배포 테스트용 샘플입니다.

---

## 0. Data Flow Definition (필수 - 프로젝트 시작 전 정의)

### 0.1 Data Source (데이터 소스)

| 항목 | 내용 |
|------|------|
| **소스 타입** | User Input + Relational DB |
| **소스 이름** | TODO 항목 텍스트 + SQLite/PostgreSQL |
| **접근 방법** | Frontend 입력 → Backend API → DB 저장/조회 |
| **인증 필요** | No (단일 사용자 MVP) |
| **비용** | 로컬 무료 / 운영 DB 사용 시 비용 발생 |
| **Rate Limit** | MVP 범위 제외 |

#### 스토리지 권장
- **개발**: SQLite (`todo.db`)
- **운영**: Railway PostgreSQL (`DATABASE_URL`)

---

### 0.2 Input (사용자 입력)

| 입력 항목 | 타입 | 예시 | 필수 |
|-----------|------|------|------|
| 할 일 제목 | String | `우유 사기` | 필수 |
| 완료 토글 | Action(Boolean) | `true/false` | 필수(액션) |
| 수정 제목 | String | `우유/빵 사기` | 선택 |
| 삭제 요청 | Action | 항목 삭제 클릭 | 필수(액션) |

---

### 0.3 Output (결과 출력)

| 출력 항목 | 형태 | 설명 |
|----------|------|------|
| TODO 목록 | 리스트 | 생성일 역순 |
| 항목 상태 | 체크/스타일 | 완료 여부 표시 |
| 처리 결과 | 메시지 | 성공/실패 안내 |

---

### 0.4 Data Flow Diagram

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│    User     │────▶│  Frontend   │────▶│   Backend   │
│   (Web)     │     │ (React/Vite)│     │  (FastAPI)  │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                               │
                                               ▼
                                         ┌──────────┐
                                         │ DB       │
                                         │SQLite/PG │
                                         └──────────┘
```

---

### 0.5 Data Refresh (데이터 갱신 주기)

| 데이터 | 갱신 주기 | 방법 |
|------|----------|------|
| TODO 목록 | 최초 진입 시 | GET `/api/v1/todos` |
| TODO 생성/수정/삭제/토글 | 액션 직후 | 성공 시 refetch |

---

### 0.6 Data Access Checklist (개발 전 확인사항)

- [x] SQLite/ PostgreSQL 공통으로 동작하는 ORM 모델 정의
- [x] 마이그레이션 파일 포함
- [x] `/health` 엔드포인트와 Railway healthcheck 경로 일치
- [x] 오류 응답 envelope 정책 정의
- [x] Frontend 액션 실패 시 사용자 메시지 노출 정책 정의

---

## 1. Project Overview

### 1.1 Purpose
Todo List MVP는 사용자가 할 일을 추가, 조회, 수정, 삭제하고 완료 상태를 토글할 수 있는 **단일 사용자 TODO 웹 애플리케이션**입니다.

### 1.2 MVP Goals (기본 기능 “풀셋”)
- TODO 생성
- TODO 목록 조회 (생성일 역순)
- TODO 제목 수정
- TODO 삭제
- TODO 완료/미완료 토글
- 성공/실패 메시지 표시
- Railway 배포 가능한 Docker 구조

> **범위 제외(Non-goals)**: 인증, 사용자별 분리, 필터(전체/완료/미완료), 우선순위, 마감일, 카테고리, 검색, 협업

---

## 2. System Architecture

### 2.1 High-Level Architecture

```
Frontend (React + Vite + TailwindCSS)
    ↕ HTTP/REST (/api/v1)
Backend (FastAPI + SQLAlchemy + Alembic)
    ↕
Database (SQLite for dev / PostgreSQL for Railway)
```

### 2.2 Component Breakdown

#### Frontend (React)
- 단일 페이지(`/`) TODO UI
- `fetch` 기반 API 클라이언트
- 로딩/에러/성공 메시지 상태 관리
- 인라인 수정 UI

#### Backend (FastAPI)
- `/health` 및 `/api/v1/todos` REST API
- Repository 인터페이스 + SQLAlchemy 구현체
- Service 레이어(비즈니스 규칙)
- 공통 응답 envelope / 예외 처리

#### Database
- `todos` 단일 테이블
- SQLAlchemy ORM 모델 + Alembic migration

---

## 3. Core Features & User Stories

### 3.1 Todo CRUD
- 사용자는 할 일 제목을 입력하여 TODO를 생성한다.
- 사용자는 저장된 TODO 목록을 확인한다.
- 사용자는 기존 TODO 제목을 수정한다.
- 사용자는 TODO를 삭제한다.

### 3.2 Completion Toggle
- 사용자는 TODO의 완료/미완료 상태를 토글한다.
- 완료된 TODO는 시각적으로 구분된다.

### 3.3 Feedback
- 사용자는 API 요청 성공/실패 메시지를 확인한다.
- 사용자는 API 실패 시 더미 데이터가 아닌 실제 오류 메시지를 본다.

---

## 4. API Design

> **규칙**: 모든 엔드포인트는 trailing slash 없이 통일 (`/api/v1/...`)

### 4.1 Response Envelope
```json
{
  "status": "success",
  "data": {},
  "error": null,
  "metadata": {
    "timestamp": "2026-02-24T00:00:00Z"
  }
}
```

### 4.2 Todo Endpoints
```
GET /health
- Response: { status, data: { ok: true } }

GET /api/v1/todos
- Response: { items: Todo[] }

POST /api/v1/todos
- Body: { title }
- Response: { item: Todo }

PATCH /api/v1/todos/{todo_id}
- Body: { title?, is_completed? }
- Response: { item: Todo }

DELETE /api/v1/todos/{todo_id}
- Response: { deleted_id }
```

---

## 5. Database Schema (SQLAlchemy ORM)

### 5.1 Models (핵심 테이블)

#### `todos`
- `id` (PK, int)
- `title` (string, max 200, not null)
- `is_completed` (bool, default false)
- `created_at` (datetime, timezone-aware)
- `updated_at` (datetime, timezone-aware)

---

## 6. Business Rules (정책/규칙)

### 6.1 입력 검증
- 제목은 공백만으로 생성/수정할 수 없다.
- 제목 최대 길이는 200자.

### 6.2 수정 정책
- `PATCH`는 `title`, `is_completed` 중 하나 이상 포함해야 한다.
- 존재하지 않는 `todo_id`는 `404`를 반환한다.

### 6.3 정렬 정책
- 목록은 `created_at DESC`, 동률 시 `id DESC`로 반환한다.

---

## 7. Caching & Performance (선택)

- MVP에서는 캐시 미사용
- 액션 후 목록 재조회(refetch)로 단순성 우선

---

## 8. Frontend Routes & UX

### 8.1 Routes
- `/` : TODO 메인 페이지

### 8.2 UI/UX Guidelines
- 심플한 단일 컬럼 레이아웃
- 모바일 우선 반응형 (`max-width` 제한)
- 성공/실패 메시지 항상 노출
- 완료 항목은 텍스트 스타일(취소선/명도)로 구분
- 이모지 미사용

---

## 9. Security Considerations

- 인증 미구현(MVP 범위 제외)임을 명시
- 입력값 서버 검증(Pydantic)
- CORS 허용 origin은 환경변수 기반 설정 가능
- 에러 응답에 내부 스택트레이스 노출 금지

---

## 10. Development Phases

### Phase 1: Foundation
- 프로젝트 구조 생성
- 공통 파일 복사
- SPEC/환경변수/README 작성

### Phase 2: Backend Core
- FastAPI + SQLAlchemy + Alembic + Repository 인터페이스 구현
- TODO CRUD API 및 테스트 구현

### Phase 3: Frontend Core
- React + Vite + Tailwind UI 구현
- API 연동 및 Vitest 테스트 구현

### Phase 4: Integration & Deployment Check
- 스크립트/도커/레일웨이 점검
- 최종 테스트/빌드 검증

---

## 11. Project Structure

```
todo-list/
├── .claude/
├── scripts/
├── frontend/
│   ├── src/
│   ├── package.json
│   └── vite.config.ts
├── backend/
│   ├── app/
│   ├── alembic/
│   ├── alembic.ini
│   └── requirements.txt
├── SPEC.md
├── Dockerfile
├── railway.toml
└── .env.example
```

---

## 12. Environment Variables

```bash
# Backend
DATABASE_URL=sqlite:///./todo.db
SECRET_KEY=change_me_in_production
LOG_LEVEL=INFO
ENVIRONMENT=development
CORS_ORIGINS=http://localhost:3000

# Frontend
VITE_API_URL=http://localhost:8000/api/v1
VITE_APP_NAME=Todo List
VITE_APP_VERSION=0.1.0
```

---

## 13. Testing Strategy

### 13.1 Backend 테스트
- Repository CRUD 단위 테스트
- API CRUD + validation + 404 테스트
- `/health` 응답 테스트

### 13.2 Frontend 테스트
- 초기 빈 상태 렌더링
- 추가/수정/삭제/완료 토글 UI 플로우
- API 실패 메시지 노출

---

## 14. Success Metrics

- TODO CRUD + 완료 토글 동작
- `bash scripts/test.sh` 통과
- `npm run build` / Backend import 성공
- `/health` 200 응답
- Railway healthcheck 경로 일치
