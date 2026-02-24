#!/usr/bin/env bash
# AI Coding Template - Development Server (Cross-platform)
# 백엔드와 프론트엔드 개발 서버를 실행합니다.
# 지원 OS: macOS, Linux, Windows (Git Bash / WSL)
#
# 사용법:
#   bash scripts/dev.sh              # 전체 실행 (기본값)
#   bash scripts/dev.sh backend      # Backend만
#   bash scripts/dev.sh frontend     # Frontend만

set -euo pipefail

# ============================================
# 색상 코드
# ============================================
GREEN="\033[92m"
YELLOW="\033[93m"
RED="\033[91m"
BLUE="\033[94m"
CYAN="\033[96m"
RESET="\033[0m"

# ============================================
# 유틸리티 함수
# ============================================
success() { echo -e "${GREEN}[OK]${RESET} $1"; }
warning() { echo -e "${YELLOW}[!]${RESET} $1"; }
error()   { echo -e "${RED}[ERROR]${RESET} $1"; }
info()    { echo -e "${BLUE}[INFO]${RESET} $1"; }

# ============================================
# OS 감지
# ============================================
get_os() {
    case "$(uname -s)" in
        Darwin) echo "macos" ;;
        MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
        *) echo "linux" ;;
    esac
}

# ============================================
# 가상환경 Python 경로
# ============================================
get_venv_python() {
    local os_type
    os_type=$(get_os)
    if [[ "$os_type" == "windows" ]]; then
        echo "venv/Scripts/python.exe"
    else
        echo "venv/bin/python"
    fi
}

# ============================================
# 포트 프로세스 종료
# ============================================
kill_port() {
    local port="$1"
    local os_type
    os_type=$(get_os)

    if [[ "$os_type" == "windows" ]]; then
        # Windows: netstat + taskkill
        local pids
        pids=$(netstat -ano 2>/dev/null | grep ":${port}" | awk '{print $5}' | sort -u) || true
        for pid in $pids; do
            if [[ -n "$pid" && "$pid" != "0" ]]; then
                taskkill //F //PID "$pid" &>/dev/null || true
            fi
        done
    else
        # macOS/Linux: lsof + kill
        local pids
        pids=$(lsof -ti :"$port" 2>/dev/null) || true
        for pid in $pids; do
            if [[ -n "$pid" ]]; then
                kill -9 "$pid" &>/dev/null || true
            fi
        done
    fi

    if [[ -n "${pids:-}" ]]; then
        info "포트 ${port} 프로세스 종료됨"
    fi
}

# ============================================
# .env 파일 로드
# ============================================
load_env() {
    if [[ -f ".env" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            # 빈 줄, 주석 건너뛰기
            line="${line%%#*}"
            line="$(echo "$line" | xargs)" 2>/dev/null || continue
            if [[ -n "$line" && "$line" == *"="* ]]; then
                local key="${line%%=*}"
                local value="${line#*=}"
                key="$(echo "$key" | xargs)"
                value="$(echo "$value" | xargs)"
                export "$key=$value"
            fi
        done < ".env"
    fi
}

# ============================================
# 로그 파일 초기화
# ============================================
clear_logs() {
    local log_files=("backend/debug.log" "frontend/debug.log")
    for log_file in "${log_files[@]}"; do
        if [[ -f "$log_file" ]]; then
            rm -f "$log_file"
        fi
    done
    info "로그 파일 초기화 완료"
}

# ============================================
# 서버 PID 저장
# ============================================
BACKEND_PID=""
FRONTEND_PID=""

# ============================================
# 서버 시작
# ============================================
start_backend() {
    local venv_python="$1"
    local project_root="$2"

    if [[ ! -d "backend" ]]; then
        error "backend/ 디렉토리가 없습니다."
        exit 1
    fi

    kill_port 8000
    sleep 0.5

    info "Backend 서버 시작 중..."

    (cd "${project_root}/backend" && "$project_root/$venv_python" -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 2>&1 | while IFS= read -r line; do
        echo -e "${CYAN}[Backend]${RESET} ${line}"
    done) &
    BACKEND_PID=$!

    success "Backend 서버 시작됨 (Port: 8000)"
    echo "   API 문서: http://localhost:8000/docs"
}

start_frontend() {
    local project_root="$1"

    if [[ ! -d "frontend" ]]; then
        error "frontend/ 디렉토리가 없습니다."
        exit 1
    fi

    kill_port 3000
    sleep 0.5

    info "Frontend 서버 시작 중..."

    (cd "${project_root}/frontend" && npm run dev 2>&1 | while IFS= read -r line; do
        echo -e "${CYAN}[Frontend]${RESET} ${line}"
    done) &
    FRONTEND_PID=$!

    success "Frontend 서버 시작됨 (Port: 3000)"
    echo "   브라우저: http://localhost:3000"
}

# ============================================
# 종료 처리 (trap)
# ============================================
cleanup() {
    echo ""
    info "서버를 종료합니다..."

    if [[ -n "$BACKEND_PID" ]]; then
        kill "$BACKEND_PID" 2>/dev/null || true
        wait "$BACKEND_PID" 2>/dev/null || true
        success "Backend 서버 종료"
        kill_port 8000
    fi

    if [[ -n "$FRONTEND_PID" ]]; then
        kill "$FRONTEND_PID" 2>/dev/null || true
        wait "$FRONTEND_PID" 2>/dev/null || true
        success "Frontend 서버 종료"
        kill_port 3000
    fi

    exit 0
}

trap cleanup SIGINT SIGTERM

# ============================================
# main
# ============================================
main() {
    echo "=================================================="
    echo "AI Coding Template - Development Server"
    echo "=================================================="
    echo ""

    # 프로젝트 루트로 이동
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_root
    project_root="$(cd "${script_dir}/.." && pwd)"
    cd "$project_root"

    # 인자 파싱
    local mode="${1:-all}"

    # 가상환경 확인
    if [[ ! -d "venv" ]]; then
        error "가상환경이 없습니다. 먼저 bash scripts/install.sh를 실행하세요."
        exit 1
    fi

    # 환경 변수 로드
    load_env

    # 로그 파일 초기화
    clear_logs

    local venv_python
    venv_python=$(get_venv_python)

    # Backend 서버
    if [[ "$mode" == "all" || "$mode" == "backend" ]]; then
        start_backend "$venv_python" "$project_root"

        if [[ "$mode" == "all" ]]; then
            sleep 2  # Backend 시작 대기
        fi
    fi

    # Frontend 서버
    if [[ "$mode" == "all" || "$mode" == "frontend" ]]; then
        start_frontend "$project_root"
    fi

    echo ""
    echo "=================================================="
    echo "개발 서버가 실행 중입니다."
    echo "종료하려면 Ctrl+C를 누르세요."
    echo "=================================================="
    echo ""

    # 메인 프로세스 대기
    wait
}

main "$@"
