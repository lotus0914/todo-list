#!/usr/bin/env bash
# AI Coding Template - Installation Script (Cross-platform)
# 비개발자도 사용할 수 있도록 모든 의존성을 자동 설치합니다.
# 지원 OS: macOS, Linux, Windows (Git Bash / WSL)
# 호환성: bash 3.2+ (macOS 기본 bash 포함)
#
# 설치 흐름:
# 1. OS 감지
# 2. Node.js 확인/자동 설치
# 3. Python 확인/자동 설치
# 4. Git 확인/자동 설치 + git config 확인
# 5. ripgrep 확인/자동 설치
# 6. MCP CLI 도구 설치 (uvx, markitdown-mcp)
# 7. MCP 서버 환경변수 설정 (대화형 입력)
# 8. Python 가상환경 생성
# 9. Backend 의존성 설치
# 10. Frontend 의존성 설치
# 11. 환경 변수 파일 생성
# 12. 최종 상태 테이블 출력

set -euo pipefail

# ============================================
# 색상 코드
# ============================================
GREEN="\033[92m"
YELLOW="\033[93m"
RED="\033[91m"
BLUE="\033[94m"
BOLD="\033[1m"
RESET="\033[0m"

# ============================================
# 유틸리티 함수
# ============================================
success() { echo -e "${GREEN}[OK]${RESET} $1"; }
warning() { echo -e "${YELLOW}[!]${RESET} $1"; }
error()   { echo -e "${RED}[ERROR]${RESET} $1"; }
info()    { echo -e "${BLUE}[INFO]${RESET} $1"; }

command_exists() { command -v "$1" &>/dev/null; }

run_cmd() {
    if "$@" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

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
# Python 명령어 감지
# ============================================
get_python_cmd() {
    if command_exists python3; then
        echo "python3"
    elif command_exists python; then
        if python --version 2>&1 | grep -q "Python 3"; then
            echo "python"
        fi
    elif command_exists py; then
        # Windows Python Launcher
        if py -3 --version &>/dev/null; then
            echo "py -3"
        fi
    fi
}

get_pip_cmd() {
    if command_exists pip3; then
        echo "pip3"
    elif command_exists pip; then
        echo "pip"
    fi
}

get_venv_python() {
    local os_type
    os_type=$(get_os)
    if [[ "$os_type" == "windows" ]]; then
        echo "venv/Scripts/python.exe"
    else
        echo "venv/bin/python"
    fi
}

get_venv_pip() {
    local os_type
    os_type=$(get_os)
    if [[ "$os_type" == "windows" ]]; then
        echo "venv/Scripts/pip.exe"
    else
        echo "venv/bin/pip"
    fi
}

# ============================================
# Homebrew 설치 (macOS)
# ============================================
ensure_homebrew() {
    if command_exists brew; then
        return 0
    fi
    info "Homebrew가 설치되어 있지 않습니다. 설치를 시도합니다..."
    if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        success "Homebrew 설치 완료"
        return 0
    else
        error "Homebrew 설치 실패"
        echo "  수동 설치: https://brew.sh"
        return 1
    fi
}

# ============================================
# 도구 자동 설치
# ============================================
install_tool() {
    local tool_name="$1"
    local os_type="$2"
    local cmd=""
    local fallback_url=""

    case "$tool_name" in
        node)
            fallback_url="https://nodejs.org"
            case "$os_type" in
                macos)
                    ensure_homebrew || { echo "  수동 설치: $fallback_url"; return 1; }
                    cmd="brew install node"
                    ;;
                linux)
                    cmd="curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && sudo apt-get install -y nodejs"
                    ;;
                windows) cmd="winget install OpenJS.NodeJS.LTS" ;;
            esac
            ;;
        python3)
            fallback_url="https://python.org"
            case "$os_type" in
                macos)
                    ensure_homebrew || { echo "  수동 설치: $fallback_url"; return 1; }
                    cmd="brew install python@3.11"
                    ;;
                linux)
                    cmd="sudo apt-get update && sudo apt-get install -y python3 python3-pip python3-venv"
                    ;;
                windows) cmd="winget install Python.Python.3.11" ;;
            esac
            ;;
        git)
            fallback_url="https://git-scm.com"
            case "$os_type" in
                macos)
                    ensure_homebrew || { echo "  수동 설치: $fallback_url"; return 1; }
                    cmd="brew install git"
                    ;;
                linux)
                    cmd="sudo apt-get update && sudo apt-get install -y git"
                    ;;
                windows) cmd="winget install Git.Git" ;;
            esac
            ;;
        rg)
            fallback_url="https://github.com/BurntSushi/ripgrep#installation"
            case "$os_type" in
                macos)
                    ensure_homebrew || { echo "  수동 설치: $fallback_url"; return 1; }
                    cmd="brew install ripgrep"
                    ;;
                linux)
                    cmd="sudo apt-get update && sudo apt-get install -y ripgrep"
                    ;;
                windows) cmd="winget install BurntSushi.ripgrep.MSVC" ;;
            esac
            ;;
        *)
            error "알 수 없는 도구: $tool_name"
            return 1
            ;;
    esac

    if [[ -z "$cmd" ]]; then
        error "${os_type}에서 ${tool_name} 자동 설치를 지원하지 않습니다."
        return 1
    fi

    info "${tool_name} 자동 설치를 시도합니다..."
    echo "  실행: $cmd"
    if eval "$cmd"; then
        success "${tool_name} 설치 완료"
        return 0
    else
        error "${tool_name} 자동 설치 실패"
        [[ -n "$fallback_url" ]] && echo "  수동 설치: $fallback_url"
        return 1
    fi
}

# ============================================
# MCP CLI 도구 설치
# ============================================

# MCP 도구 결과 저장 (bash 3 호환 - 개별 변수)
MCP_STATUS_npx="SKIP"
MCP_STATUS_uvx="SKIP"
MCP_STATUS_markitdown="SKIP"
MCP_VERSION_npx="-"
MCP_VERSION_uvx="-"
MCP_VERSION_markitdown="-"

install_mcp_tools() {
    local pip_cmd="$1"

    # npx 확인 (Node.js에 포함)
    if command_exists npx; then
        local npx_ver
        npx_ver=$(npx --version 2>/dev/null || echo "?")
        success "npx ${npx_ver} (Node.js에 포함)"
        MCP_STATUS_npx="OK"
        MCP_VERSION_npx="$npx_ver"
    else
        warning "npx를 찾을 수 없습니다. Node.js가 올바르게 설치되었는지 확인하세요."
        MCP_STATUS_npx="FAIL"
        MCP_VERSION_npx="-"
    fi

    # uvx (pip install uv)
    if command_exists uvx; then
        local uvx_ver
        uvx_ver=$(uvx --version 2>/dev/null || echo "?")
        success "uvx 이미 설치됨 (${uvx_ver})"
        MCP_STATUS_uvx="OK"
        MCP_VERSION_uvx="$uvx_ver"
    else
        info "uvx 설치 중 (pip install uv)..."
        if $pip_cmd install uv &>/dev/null; then
            local uvx_ver
            uvx_ver=$(uvx --version 2>/dev/null || echo "설치됨")
            success "uvx 설치 완료 (${uvx_ver})"
            MCP_STATUS_uvx="OK"
            MCP_VERSION_uvx="$uvx_ver"
        else
            warning "uvx 설치 실패 (pip install uv). serena MCP 서버를 사용할 수 없습니다."
            MCP_STATUS_uvx="FAIL"
            MCP_VERSION_uvx="-"
        fi
    fi

    # markitdown-mcp
    if command_exists markitdown-mcp; then
        success "markitdown-mcp 이미 설치됨"
        MCP_STATUS_markitdown="OK"
        MCP_VERSION_markitdown="-"
    else
        info "markitdown-mcp 설치 중..."
        if $pip_cmd install markitdown-mcp &>/dev/null; then
            success "markitdown-mcp 설치 완료"
            MCP_STATUS_markitdown="OK"
            MCP_VERSION_markitdown="-"
        else
            warning "markitdown-mcp 설치 실패. markitdown MCP 서버를 사용할 수 없습니다."
            MCP_STATUS_markitdown="FAIL"
            MCP_VERSION_markitdown="-"
        fi
    fi
}

# ============================================
# Shell profile 경로
# ============================================
get_shell_profile() {
    local os_type
    os_type=$(get_os)

    if [[ "$os_type" == "windows" ]]; then
        echo ""
        return
    fi

    local shell_name="${SHELL:-}"
    local home="$HOME"

    if [[ "$shell_name" == *zsh* ]]; then
        echo "${home}/.zshrc"
    elif [[ "$shell_name" == *bash* ]]; then
        if [[ "$os_type" == "macos" ]]; then
            echo "${home}/.bash_profile"
        else
            echo "${home}/.bashrc"
        fi
    else
        echo "${home}/.profile"
    fi
}

# ============================================
# 대화형 환경변수 입력
# ============================================
ask_env_variable() {
    local var_name="$1"
    local description="$2"
    local hint="$3"

    # non-interactive 환경 확인
    if [[ ! -t 0 ]]; then
        warning "${var_name} 설정을 건너뜁니다 (non-interactive 모드)."
        echo ""
        return
    fi

    echo ""
    echo -e "  ${BOLD}${description}${RESET}"
    echo "  ${hint}"
    echo "  (건너뛰려면 Enter를 누르세요)"
    echo ""
    read -r -p "  ${var_name}= " value || { echo ""; return; }

    echo "${value}"
}

save_env_to_profile() {
    local var_name="$1"
    local value="$2"
    local profile_path="$3"
    local export_line="export ${var_name}=\"${value}\""

    if [[ -z "$profile_path" ]]; then
        # Windows: setx로 설정
        if setx "$var_name" "$value" &>/dev/null; then
            success "${var_name}을(를) 시스템 환경변수에 저장했습니다."
            return 0
        else
            error "${var_name} 저장 실패"
            return 1
        fi
    fi

    # 이미 존재하는지 확인
    if [[ -f "$profile_path" ]] && grep -q "^export ${var_name}=" "$profile_path"; then
        # 기존 값 업데이트
        sed -i.bak "s|^export ${var_name}=.*|${export_line}|" "$profile_path"
        rm -f "${profile_path}.bak"
        success "${var_name}을(를) ${profile_path}에 업데이트했습니다."
        return 0
    fi

    # 새로 추가
    echo "" >> "$profile_path"
    echo "# MCP Server - ${var_name}" >> "$profile_path"
    echo "${export_line}" >> "$profile_path"

    success "${var_name}을(를) ${profile_path}에 저장했습니다."
    return 0
}

# ============================================
# MCP 서버 환경변수 설정
# ============================================

# 환경변수 결과 저장 (bash 3 호환 - 병렬 인덱스 배열)
ENV_RESULT_NAMES=()
ENV_RESULT_VALUES=()

setup_mcp_env_variables() {
    local profile_path
    profile_path=$(get_shell_profile)

    local var_names=("CONTEXT7_API_KEY" "GITHUB_PERSONAL_ACCESS_TOKEN")
    local var_descs=(
        "Context7 API Key (최신 문서 조회용 MCP 서버)"
        "GitHub Personal Access Token (GitHub MCP 서버)"
    )
    local var_hints=(
        "발급: https://context7.com"
        "발급: GitHub > Settings > Developer settings > Personal access tokens"
    )

    local i
    for i in "${!var_names[@]}"; do
        local name="${var_names[$i]}"
        local desc="${var_descs[$i]}"
        local hint="${var_hints[$i]}"
        local current_value="${!name:-}"

        if [[ -n "$current_value" ]]; then
            local masked="${current_value:0:4}***"
            success "${name} 이미 설정됨 (${masked})"
            ENV_RESULT_NAMES+=("$name")
            ENV_RESULT_VALUES+=("OK")
            continue
        fi

        local value
        value=$(ask_env_variable "$name" "$desc" "$hint")

        if [[ -n "$value" ]]; then
            save_env_to_profile "$name" "$value" "$profile_path"
            export "$name=$value"
            ENV_RESULT_NAMES+=("$name")
            ENV_RESULT_VALUES+=("OK")
        else
            warning "${name}을(를) 건너뛰었습니다. 해당 MCP 서버가 동작하지 않을 수 있습니다."
            ENV_RESULT_NAMES+=("$name")
            ENV_RESULT_VALUES+=("SKIP")
        fi
    done

    if [[ -n "$profile_path" ]]; then
        local has_ok=false
        local v
        for v in "${ENV_RESULT_VALUES[@]}"; do
            [[ "$v" == "OK" ]] && has_ok=true
        done
        if $has_ok; then
            echo ""
            info "새 터미널에서 환경변수가 적용됩니다."
            info "현재 터미널에 바로 적용하려면: source ${profile_path}"
        fi
    fi
}

# ============================================
# Git config 확인
# ============================================
check_git_config() {
    command_exists git || return

    local name email
    name=$(git config user.name 2>/dev/null || echo "")
    email=$(git config user.email 2>/dev/null || echo "")

    if [[ -n "$name" ]]; then
        success "git user.name: ${name}"
    else
        warning "git user.name이 설정되지 않았습니다."
        echo '  설정 방법: git config --global user.name "Your Name"'
    fi

    if [[ -n "$email" ]]; then
        success "git user.email: ${email}"
    else
        warning "git user.email이 설정되지 않았습니다."
        echo '  설정 방법: git config --global user.email "your@email.com"'
    fi
}

# ============================================
# 상태 테이블 출력
# ============================================

# 상태 저장용 병렬 인덱스 배열 (bash 3 호환)
STATUS_NAMES=()
STATUS_STATES=()
STATUS_VERSIONS=()

add_status() {
    local name="$1"
    local state="$2"
    local version="$3"
    STATUS_NAMES+=("$name")
    STATUS_STATES+=("$state")
    STATUS_VERSIONS+=("$version")
}

print_status_table() {
    # 컬럼 너비 계산
    local name_width=6
    local idx
    for idx in "${!STATUS_NAMES[@]}"; do
        local len=${#STATUS_NAMES[$idx]}
        (( len > name_width )) && name_width=$len
    done

    local status_width=8
    local ver_width=12

    echo ""
    echo -e "${BOLD}설치 상태 요약${RESET}"

    # 구분선
    local sep="|"
    sep+=$(printf '%0.s-' $(seq 1 $((name_width + 2))))
    sep+="|"
    sep+=$(printf '%0.s-' $(seq 1 $((status_width + 2))))
    sep+="|"
    sep+=$(printf '%0.s-' $(seq 1 $((ver_width + 2))))
    sep+="|"

    echo "$sep"
    printf "| %-${name_width}s | %-${status_width}s | %-${ver_width}s |\n" "항목" "상태" "버전"
    echo "$sep"

    for idx in "${!STATUS_NAMES[@]}"; do
        local name="${STATUS_NAMES[$idx]}"
        local state="${STATUS_STATES[$idx]}"
        local version="${STATUS_VERSIONS[$idx]}"
        local colored_state

        case "$state" in
            OK)   colored_state="${GREEN}$(printf "%-${status_width}s" "$state")${RESET}" ;;
            SKIP) colored_state="${YELLOW}$(printf "%-${status_width}s" "$state")${RESET}" ;;
            *)    colored_state="${RED}$(printf "%-${status_width}s" "$state")${RESET}" ;;
        esac

        printf "| %-${name_width}s | %b | %-${ver_width}s |\n" "$name" "$colored_state" "$version"
    done

    echo "$sep"
}

# ============================================
# main
# ============================================
main() {
    echo "=================================================="
    echo "AI Coding Template - Installation"
    echo "=================================================="
    echo ""

    local os_type
    os_type=$(get_os)
    info "감지된 OS: ${os_type} ($(uname -s) $(uname -r))"
    echo ""

    # 프로젝트 루트 디렉토리로 이동
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_root
    project_root="$(cd "${script_dir}/.." && pwd)"
    cd "$project_root"
    info "프로젝트 디렉토리: ${project_root}"
    echo ""

    # ============================================
    # 1. Node.js 확인 / 자동 설치
    # ============================================
    echo "1. Node.js 확인 중..."

    if command_exists node; then
        local node_ver
        node_ver=$(node -v 2>/dev/null)
        success "Node.js ${node_ver} 이미 설치됨"
        add_status "Node.js" "OK" "$node_ver"
    else
        warning "Node.js가 설치되어 있지 않습니다."
        if install_tool "node" "$os_type"; then
            local node_ver
            node_ver=$(node -v 2>/dev/null || echo "설치됨")
            add_status "Node.js" "OK" "$node_ver"
        else
            error "Node.js 설치에 실패했습니다. 수동으로 설치 후 다시 실행하세요."
            add_status "Node.js" "FAIL" "-"
            exit 1
        fi
    fi

    if command_exists npm; then
        local npm_ver
        npm_ver=$(npm -v 2>/dev/null || echo "?")
        add_status "npm" "OK" "$npm_ver"
    else
        error "npm이 설치되어 있지 않습니다. Node.js를 재설치하세요."
        add_status "npm" "FAIL" "-"
        exit 1
    fi

    echo ""

    # ============================================
    # 2. Python 확인 / 자동 설치
    # ============================================
    echo "2. Python 확인 중..."

    local python_cmd
    python_cmd=$(get_python_cmd)

    if [[ -n "$python_cmd" ]]; then
        local py_ver
        py_ver=$($python_cmd --version 2>&1)
        success "${py_ver} 이미 설치됨"
        add_status "Python" "OK" "${py_ver#Python }"
    else
        warning "Python 3가 설치되어 있지 않습니다."
        if install_tool "python3" "$os_type"; then
            python_cmd=$(get_python_cmd)
            if [[ -n "$python_cmd" ]]; then
                local py_ver
                py_ver=$($python_cmd --version 2>&1 || echo "설치됨")
                add_status "Python" "OK" "${py_ver#Python }"
            else
                error "Python 설치 후에도 명령어를 찾을 수 없습니다. PATH를 확인하세요."
                add_status "Python" "FAIL" "-"
                exit 1
            fi
        else
            error "Python 설치에 실패했습니다. 수동으로 설치 후 다시 실행하세요."
            add_status "Python" "FAIL" "-"
            exit 1
        fi
    fi

    echo ""

    # ============================================
    # 3. Git 확인 / 자동 설치 + git config 확인
    # ============================================
    echo "3. Git 확인 중..."

    if command_exists git; then
        local git_ver
        git_ver=$(git --version 2>/dev/null | sed 's/git version //')
        success "Git ${git_ver} 이미 설치됨"
        add_status "Git" "OK" "$git_ver"
    else
        warning "Git이 설치되어 있지 않습니다."
        if install_tool "git" "$os_type"; then
            local git_ver
            git_ver=$(git --version 2>/dev/null | sed 's/git version //' || echo "설치됨")
            add_status "Git" "OK" "$git_ver"
        else
            warning "Git 설치에 실패했습니다. 버전 관리 기능이 제한됩니다."
            add_status "Git" "FAIL" "-"
        fi
    fi

    # git config 확인
    check_git_config

    echo ""

    # ============================================
    # 4. ripgrep 확인 / 자동 설치
    # ============================================
    echo "4. ripgrep 확인 중..."

    if command_exists rg; then
        local rg_ver
        rg_ver=$(rg --version 2>/dev/null | head -n1 | sed 's/ripgrep //')
        success "ripgrep ${rg_ver} 이미 설치됨"
        add_status "ripgrep" "OK" "$rg_ver"
    else
        warning "ripgrep이 설치되어 있지 않습니다."
        if install_tool "rg" "$os_type"; then
            local rg_ver
            rg_ver=$(rg --version 2>/dev/null | head -n1 | sed 's/ripgrep //' || echo "설치됨")
            add_status "ripgrep" "OK" "$rg_ver"
        else
            warning "ripgrep 설치에 실패했습니다. ripgrep MCP 서버가 동작하지 않을 수 있습니다."
            add_status "ripgrep" "FAIL" "-"
        fi
    fi

    echo ""

    # ============================================
    # 5. MCP CLI 도구 설치
    # ============================================
    echo "5. MCP CLI 도구 확인/설치 중..."

    local pip_cmd
    pip_cmd=$(get_pip_cmd)
    if [[ -z "$pip_cmd" ]]; then
        pip_cmd="${python_cmd} -m pip"
    fi
    install_mcp_tools "$pip_cmd"

    add_status "npx (MCP)" "${MCP_STATUS_npx}" "${MCP_VERSION_npx}"
    add_status "uvx (MCP)" "${MCP_STATUS_uvx}" "${MCP_VERSION_uvx}"
    add_status "markitdown (MCP)" "${MCP_STATUS_markitdown}" "${MCP_VERSION_markitdown}"

    echo ""

    # ============================================
    # 6. MCP 서버 환경변수 설정
    # ============================================
    echo "6. MCP 서버 환경변수 확인 중..."

    setup_mcp_env_variables

    local ei
    for ei in "${!ENV_RESULT_NAMES[@]}"; do
        add_status "${ENV_RESULT_NAMES[$ei]}" "${ENV_RESULT_VALUES[$ei]}" "-"
    done

    echo ""

    # ============================================
    # 7. Python 가상환경 생성
    # ============================================
    echo "7. Python 가상환경 생성 중..."

    if [[ ! -d "venv" ]]; then
        if $python_cmd -m venv venv; then
            success "가상환경 생성 완료"
            add_status "venv" "OK" "-"
        else
            error "가상환경 생성 실패"
            if [[ "$os_type" == "linux" ]]; then
                info "python3-venv 패키지가 필요할 수 있습니다:"
                echo "  sudo apt-get install -y python3-venv"
            fi
            add_status "venv" "FAIL" "-"
        fi
    else
        warning "가상환경이 이미 존재합니다. 건너뜁니다."
        add_status "venv" "OK" "기존"
    fi

    echo ""

    # ============================================
    # 8. Backend 의존성 설치
    # ============================================
    echo "8. Backend 의존성 설치 중..."

    local venv_pip
    venv_pip=$(get_venv_pip)

    if [[ -f "backend/requirements.txt" ]]; then
        # pip 업그레이드
        $venv_pip install --upgrade pip &>/dev/null || true
        # 패키지 설치
        if $venv_pip install -r backend/requirements.txt; then
            success "Backend 패키지 설치 완료"
            add_status "Backend 의존성" "OK" "-"
        else
            error "Backend 패키지 설치 실패"
            add_status "Backend 의존성" "FAIL" "-"
        fi
    else
        warning "backend/requirements.txt가 없습니다."
        info "프로젝트 생성 후 다시 install.sh를 실행하세요."
        add_status "Backend 의존성" "SKIP" "-"
    fi

    echo ""

    # ============================================
    # 9. Frontend 의존성 설치
    # ============================================
    echo "9. Frontend 의존성 설치 중..."

    if [[ -f "frontend/package.json" ]]; then
        if (cd frontend && npm install); then
            success "Frontend 패키지 설치 완료"
            add_status "Frontend 의존성" "OK" "-"
        else
            error "Frontend 패키지 설치 실패"
            add_status "Frontend 의존성" "FAIL" "-"
        fi
    else
        warning "frontend/package.json이 없습니다."
        info "프로젝트 생성 후 다시 install.sh를 실행하세요."
        add_status "Frontend 의존성" "SKIP" "-"
    fi

    echo ""

    # ============================================
    # 10. 환경 변수 파일 생성
    # ============================================
    echo "10. 환경 변수 파일 확인 중..."

    if [[ ! -f ".env" ]]; then
        if [[ -f ".env.example" ]]; then
            cp .env.example .env
            success ".env 파일 생성 완료"
            warning ".env 파일을 열어서 필요한 값을 설정하세요!"
            add_status ".env" "OK" "생성됨"
        else
            warning ".env.example 파일이 없습니다."
            add_status ".env" "SKIP" "-"
        fi
    else
        success ".env 파일이 이미 존재합니다."
        add_status ".env" "OK" "기존"
    fi

    echo ""

    # ============================================
    # 11. 최종 상태 테이블 출력
    # ============================================
    echo "=================================================="
    print_status_table
    echo ""

    # 실패 항목 확인
    local failed=()
    local fi_idx
    for fi_idx in "${!STATUS_NAMES[@]}"; do
        [[ "${STATUS_STATES[$fi_idx]}" == "FAIL" ]] && failed+=("${STATUS_NAMES[$fi_idx]}")
    done

    if [[ ${#failed[@]} -gt 0 ]]; then
        local failed_str
        failed_str=$(IFS=', '; echo "${failed[*]}")
        warning "다음 항목이 실패했습니다: ${failed_str}"
        echo "  문제를 해결한 후 다시 실행하세요: bash scripts/install.sh"
    else
        echo -e "${GREEN}설치가 완료되었습니다!${RESET}"
    fi

    echo ""
    echo "다음 단계:"
    echo "  1. 개발 서버 실행: bash scripts/dev.sh"
    echo "  2. 테스트 실행: bash scripts/test.sh"
    echo ""
    echo "문제가 있으면 Claude Code에게 물어보세요:"
    echo '  "에러 해결해줘: [에러 메시지]"'
    echo ""
}

main "$@"
