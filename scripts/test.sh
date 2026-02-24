#!/usr/bin/env bash
# AI Coding Template - Test Runner (Cross-platform)
# 유닛 테스트, 린트, 통합 테스트를 실행합니다.
# 지원 OS: macOS, Linux, Windows (Git Bash / WSL)
#
# 사용법:
#   bash scripts/test.sh              # 전체 실행 (기본값)
#   bash scripts/test.sh lint         # 린트만
#   bash scripts/test.sh backend      # Backend 테스트만
#   bash scripts/test.sh frontend     # Frontend 테스트만
#   bash scripts/test.sh --coverage   # 커버리지 리포트 포함

set -euo pipefail

# ============================================
# 색상 코드
# ============================================
GREEN="\033[92m"
YELLOW="\033[93m"
RED="\033[91m"
BLUE="\033[94m"
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
# .env 파일 로드
# ============================================
load_env() {
    if [[ -f ".env" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
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
# 결과 저장
# ============================================
# 결과 저장용 병렬 인덱스 배열 (bash 3 호환)
RESULT_NAMES=()
RESULT_STATES=()

add_result() {
    local name="$1"
    local passed="$2"  # true / false
    RESULT_NAMES+=("$name")
    RESULT_STATES+=("$passed")
}

# ============================================
# 린트 검사 (return 0=pass, 1=fail)
# ============================================
run_lint() {
    info "코드 린트 검사 중..."
    local all_passed=true
    local venv_python
    venv_python=$(get_venv_python)

    # Backend 린트 (ruff → flake8 fallback)
    if [[ -d "backend" ]]; then
        info "Backend 린트 검사..."

        local ruff_output ruff_rc
        ruff_output=$(cd backend && "$project_root/$venv_python" -m ruff check . 2>&1) && ruff_rc=0 || ruff_rc=$?

        if [[ $ruff_rc -eq 0 ]]; then
            success "Backend 린트 통과 (ruff)"
        elif echo "$ruff_output" | grep -q "No module named ruff"; then
            # flake8 fallback
            local flake8_output flake8_rc
            flake8_output=$(cd backend && "$project_root/$venv_python" -m flake8 app 2>&1) && flake8_rc=0 || flake8_rc=$?

            if [[ $flake8_rc -eq 0 ]]; then
                success "Backend 린트 통과 (flake8)"
            elif echo "$flake8_output" | grep -q "No module named flake8"; then
                warning "Backend 린터가 설치되지 않음 (pip install ruff)"
            else
                error "Backend 린트 실패"
                echo "$flake8_output"
                all_passed=false
            fi
        else
            error "Backend 린트 실패"
            echo "$ruff_output"
            all_passed=false
        fi
    fi

    # Frontend 린트 (ESLint)
    if [[ -f "frontend/package.json" ]]; then
        info "Frontend 린트 검사..."

        if grep -q '"lint"' frontend/package.json; then
            if (cd frontend && npm run lint); then
                success "Frontend 린트 통과"
            else
                error "Frontend 린트 실패"
                all_passed=false
            fi
        else
            warning "Frontend 린트 스크립트가 설정되지 않음"
        fi
    fi

    [[ "$all_passed" == "true" ]]
}

# ============================================
# Backend 테스트 (return 0=pass, 1=fail)
# ============================================
run_backend_tests() {
    local coverage="${1:-false}"
    info "Backend 테스트 실행 중..."

    local venv_python
    venv_python=$(get_venv_python)

    # 테스트 경로 찾기
    local test_path=""
    if [[ -d "tests/backend" ]]; then
        test_path="tests/backend"
    elif [[ -d "backend/tests" ]]; then
        test_path="backend/tests"
    fi

    if [[ -z "$test_path" ]]; then
        warning "Backend 테스트 디렉토리가 없습니다."
        echo "   예상 경로: tests/backend/ 또는 backend/tests/"
        return 0  # 테스트가 없으면 통과로 처리
    fi

    local cmd="$venv_python -m pytest $test_path -v"
    if [[ "$coverage" == "true" ]]; then
        cmd="$venv_python -m pytest $test_path -v --cov=backend/app --cov-report=html --cov-report=term"
    fi

    if $cmd; then
        success "Backend 테스트 통과"
        return 0
    else
        error "Backend 테스트 실패"
        return 1
    fi
}

# ============================================
# Frontend 테스트 (return 0=pass, 1=fail)
# ============================================
run_frontend_tests() {
    local coverage="${1:-false}"
    info "Frontend 테스트 실행 중..."

    if [[ ! -f "frontend/package.json" ]]; then
        warning "frontend/package.json이 없습니다."
        return 0
    fi

    if ! grep -q '"test"' frontend/package.json; then
        warning "Frontend 테스트 스크립트가 설정되지 않음"
        return 0
    fi

    local cmd="npm run test"
    if [[ "$coverage" == "true" ]]; then
        cmd="npm run test:coverage"
    fi

    if (cd frontend && $cmd); then
        success "Frontend 테스트 통과"
        return 0
    else
        error "Frontend 테스트 실패"
        return 1
    fi
}

# ============================================
# 결과 테이블 출력 (return 0=all pass, 1=has fail)
# ============================================
print_results() {
    echo ""
    echo "=================================================="
    echo "테스트 결과"
    echo "=================================================="
    echo ""
    echo "| 구분 | 결과 |"
    echo "|------|------|"

    local all_passed=true
    local idx
    for idx in "${!RESULT_NAMES[@]}"; do
        local name="${RESULT_NAMES[$idx]}"
        local passed="${RESULT_STATES[$idx]}"
        if [[ "$passed" == "true" ]]; then
            echo -e "| ${name} | ${GREEN}PASS${RESET} |"
        else
            echo -e "| ${name} | ${RED}FAIL${RESET} |"
            all_passed=false
        fi
    done

    echo ""
    if [[ "$all_passed" == "true" ]]; then
        echo -e "${GREEN}최종 결과: PASS${RESET}"
        return 0
    else
        echo -e "${RED}최종 결과: FAIL${RESET}"
        return 1
    fi
}

# ============================================
# main
# ============================================
main() {
    echo "=================================================="
    echo "AI Coding Template - Test Runner"
    echo "=================================================="
    echo ""

    # 프로젝트 루트로 이동
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_root
    project_root="$(cd "${script_dir}/.." && pwd)"
    cd "$project_root"

    # 인자 파싱
    local mode="all"
    local coverage=false

    for arg in "$@"; do
        case "$arg" in
            all|lint|backend|frontend) mode="$arg" ;;
            --coverage) coverage=true ;;
            *)
                echo "사용법: bash scripts/test.sh [all|lint|backend|frontend] [--coverage]"
                exit 1
                ;;
        esac
    done

    # 가상환경 확인
    if [[ ! -d "venv" ]]; then
        error "가상환경이 없습니다. 먼저 bash scripts/install.sh를 실행하세요."
        exit 1
    fi

    # 환경 변수 로드
    load_env

    # 테스트 실행 (set +e로 개별 실패가 스크립트를 종료하지 않게)
    set +e

    case "$mode" in
        lint)
            run_lint && add_result "Lint" "true" || add_result "Lint" "false"
            ;;
        backend)
            run_backend_tests "$coverage" && add_result "Backend" "true" || add_result "Backend" "false"
            ;;
        frontend)
            run_frontend_tests "$coverage" && add_result "Frontend" "true" || add_result "Frontend" "false"
            ;;
        all)
            run_lint && add_result "Lint" "true" || add_result "Lint" "false"
            echo ""
            run_backend_tests "$coverage" && add_result "Backend" "true" || add_result "Backend" "false"
            echo ""
            run_frontend_tests "$coverage" && add_result "Frontend" "true" || add_result "Frontend" "false"
            ;;
    esac

    set -e

    print_results
    local final_rc=$?

    if [[ "$coverage" == "true" ]]; then
        echo ""
        info "커버리지 리포트: backend/htmlcov/index.html"
    fi

    if [[ $final_rc -ne 0 ]]; then
        echo ""
        echo "문제 해결 방법:"
        echo '  1. Claude Code에게 "테스트 실패 해결해줘"라고 요청'
        echo "  2. 에러 메시지를 확인하고 해당 파일 수정"
        exit 1
    fi
}

main "$@"
