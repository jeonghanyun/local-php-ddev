#!/bin/bash

# ANSI 색상 코드
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
NC="\033[0m" # No Color

# 로그 함수
log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

log_title() {
  echo -e "${BLUE}$1${NC}"
}

log_project() {
  echo -e "${CYAN}$1${NC}"
}

# 스크립트 사용법 출력
show_usage() {
  echo "DDEV 프로젝트 상태 확인 스크립트"
  echo ""
  echo "사용법: $0 [옵션]"
  echo ""
  echo "옵션:"
  echo "  -a, --all       모든 프로젝트 상태 표시 (기본값)"
  echo "  -n, --name      특정 프로젝트 이름으로 상태 확인"
  echo "  -l, --list      설치된 프로젝트 목록만 표시"
  echo "  -h, --help      도움말 표시"
  echo ""
  echo "예시:"
  echo "  $0               모든 프로젝트 상태 표시"
  echo "  $0 -n my-wp-site 'my-wp-site' 프로젝트 상태 표시"
  echo "  $0 -l            프로젝트 목록만 표시"
}

# DDEV 설치 확인
check_ddev() {
  if ! command -v ddev &> /dev/null; then
    log_error "DDEV가 설치되어 있지 않습니다."
    log_info "설치 명령어: ./install.sh"
    exit 1
  fi
}

# 모든 프로젝트 상태 표시
show_all_projects() {
  local projects=$(ddev list | grep -v "^CONTAI" | grep -v "^$" | tail -n +2)
  
  if [ -z "$projects" ]; then
    log_warning "실행 중인 DDEV 프로젝트가 없습니다."
    return
  fi
  
  log_title "======= 모든 DDEV 프로젝트 상태 ======="
  echo "$projects"
  echo ""
  log_info "특정 프로젝트 상세 정보: $0 -n 프로젝트이름"
}

# 프로젝트 목록 표시
show_project_list() {
  local script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
  local project_list_file="$script_dir/ddev-projects/project-list.json"
  
  if [ ! -f "$project_list_file" ]; then
    log_warning "프로젝트 목록 파일이 없습니다: $project_list_file"
    return
  fi
  
  log_title "======= 설치된 DDEV 프로젝트 목록 ======="
  local projects=$(cat "$project_list_file" | sed 's/\[//g' | sed 's/\]//g' | sed 's/,//g' | sed 's/"//g')
  local count=0
  
  while read -r project; do
    if [ -n "$project" ]; then
      project=$(echo "$project" | xargs)  # 공백 제거
      echo " - $project"
      ((count++))
    fi
  done <<< "$projects"
  
  echo ""
  log_info "총 $count 개의 프로젝트가 등록되어 있습니다."
}

# 특정 프로젝트 상태 표시
show_project_status() {
  local project_name=$1
  
  # 프로젝트 존재 확인
  if ! ddev list | grep -q "$project_name"; then
    log_error "프로젝트 '$project_name'이 실행 중이 아니거나 존재하지 않습니다."
    log_info "프로젝트 시작 명령어: ddev start -a"
    exit 1
  fi
  
  log_title "======= '$project_name' 프로젝트 상태 ======="
  ddev describe "$project_name"
  
  echo ""
  log_info "유용한 명령어:"
  log_info "  ddev start $project_name  - 프로젝트 시작"
  log_info "  ddev stop $project_name   - 프로젝트 중지"
  log_info "  ddev ssh $project_name    - 프로젝트 SSH 접속"
}

# Docker 실행 확인
check_docker() {
  if ! docker info &> /dev/null; then
    log_error "Docker가 실행되고 있지 않습니다. Docker를 시작한 후 다시 시도해주세요."
    exit 1
  fi
}

# 메인 스크립트 시작

# 기본값 설정
SHOW_ALL=true
PROJECT_NAME=""
LIST_ONLY=false

# 명령줄 인수 파싱
while (( "$#" )); do
  case "$1" in
    -a|--all)
      SHOW_ALL=true
      shift
      ;;
    -n|--name)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        PROJECT_NAME=$2
        SHOW_ALL=false
        shift 2
      else
        log_error "오류: --name 인수 누락"
        show_usage
        exit 1
      fi
      ;;
    -l|--list)
      LIST_ONLY=true
      SHOW_ALL=false
      shift
      ;;
    -h|--help)
      show_usage
      exit 0
      ;;
    --) # 나머지 인수는 더 이상 파싱하지 않음
      shift
      break
      ;;
    -*|--*=) # 지원되지 않는 플래그
      log_error "오류: 지원되지 않는 플래그 $1"
      show_usage
      exit 1
      ;;
    *) # 알 수 없는 옵션
      log_error "오류: 알 수 없는 옵션 $1"
      show_usage
      exit 1
      ;;
  esac
done

# DDEV 및 Docker 확인
check_ddev
check_docker

# 프로젝트 목록 표시
if [ "$LIST_ONLY" = true ]; then
  show_project_list
  exit 0
fi

# 특정 프로젝트 상태 표시
if [ -n "$PROJECT_NAME" ]; then
  show_project_status "$PROJECT_NAME"
  exit 0
fi

# 모든 프로젝트 상태 표시
if [ "$SHOW_ALL" = true ]; then
  show_all_projects
  show_project_list
  exit 0
fi 