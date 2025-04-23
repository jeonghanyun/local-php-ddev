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
  echo "DDEV 프로젝트 중지 스크립트"
  echo ""
  echo "사용법: $0 [옵션]"
  echo ""
  echo "옵션:"
  echo "  -a, --all       모든 프로젝트 중지 (기본값)"
  echo "  -n, --name      특정 프로젝트 이름으로 중지"
  echo "  -l, --list      실행 중인 프로젝트 목록만 표시"
  echo "  -h, --help      도움말 표시"
  echo ""
  echo "예시:"
  echo "  $0               모든 프로젝트 중지"
  echo "  $0 -n my-wp-site 'my-wp-site' 프로젝트만 중지"
  echo "  $0 -l            실행 중인 프로젝트 목록만 표시"
}

# DDEV 설치 확인
check_ddev() {
  if ! command -v ddev &> /dev/null; then
    log_error "DDEV가 설치되어 있지 않습니다."
    log_info "설치 명령어: ./install.sh"
    exit 1
  fi
}

# Docker 실행 확인
check_docker() {
  if ! docker info &> /dev/null; then
    log_error "Docker가 실행되고 있지 않습니다. Docker를 시작한 후 다시 시도해주세요."
    exit 1
  fi
}

# 실행 중인 프로젝트 목록 가져오기
get_running_projects() {
  local running_projects=$(ddev list 2>/dev/null | grep -v "CONTAINER" | grep -v "Router" | grep "running" | awk '{print $1}')
  echo "$running_projects"
}

# 프로젝트 목록 가져오기
get_project_list() {
  local script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
  local project_list_file="$script_dir/ddev-projects/project-list.json"
  
  if [ ! -f "$project_list_file" ]; then
    log_warning "프로젝트 목록 파일이 없습니다: $project_list_file"
    return
  fi
  
  # 프로젝트 목록 가져오기
  local projects=$(cat "$project_list_file" | sed 's/\[//g' | sed 's/\]//g' | sed 's/,//g' | sed 's/"//g')
  echo "$projects"
}

# 실행 중인 프로젝트 목록 표시
show_running_projects() {
  local running_projects=$(get_running_projects)
  
  if [ -z "$running_projects" ]; then
    log_warning "실행 중인 DDEV 프로젝트가 없습니다."
    return 1
  fi
  
  log_title "======= 실행 중인 DDEV 프로젝트 ======="
  local count=0
  
  echo "$running_projects" | while read -r project; do
    if [ -n "$project" ]; then
      # 프로젝트 URL 가져오기
      local url=$(ddev describe $project 2>/dev/null | grep -o 'https://.*\.ddev\.site' | head -n 1)
      if [ -n "$url" ]; then
        echo " - $project (URL: $url)"
      else
        echo " - $project"
      fi
      
      ((count++))
    fi
  done
  
  count=$(echo "$running_projects" | wc -l)
  
  echo ""
  log_info "총 $count 개의 프로젝트가 실행 중입니다."
  log_info "프로젝트 중지 명령어: $0 -n 프로젝트이름"
  
  return 0
}

# 특정 프로젝트 중지
stop_project() {
  local project_name=$1
  
  # 프로젝트가 실행 중인지 확인
  if ! ddev list 2>/dev/null | grep -q "^$project_name.*running"; then
    log_warning "프로젝트 '$project_name'이 실행 중이 아닙니다."
    return 0
  fi
  
  log_info "프로젝트 '$project_name' 중지 중..."
  
  # 프로젝트 중지
  ddev stop "$project_name"
  
  if [ $? -ne 0 ]; then
    log_error "프로젝트 '$project_name' 중지에 실패했습니다."
    return 1
  fi
  
  log_info "프로젝트 '$project_name'이 성공적으로 중지되었습니다."
  return 0
}

# 모든 프로젝트 중지
stop_all_projects() {
  local running_projects=$(get_running_projects)
  
  if [ -z "$running_projects" ]; then
    log_warning "실행 중인 DDEV 프로젝트가 없습니다."
    return 0
  fi
  
  log_title "======= 모든 프로젝트 중지 ======="
  log_info "실행 중인 모든 DDEV 프로젝트를 중지합니다..."
  
  # 모든 프로젝트 중지
  ddev stop
  
  if [ $? -ne 0 ]; then
    log_error "일부 프로젝트 중지에 실패했습니다."
    return 1
  fi
  
  log_info "모든 프로젝트가 성공적으로 중지되었습니다."
  return 0
}

# 메인 스크립트 시작

# 기본값 설정
STOP_ALL=true
PROJECT_NAME=""
LIST_ONLY=false

# 명령줄 인수 파싱
while (( "$#" )); do
  case "$1" in
    -a|--all)
      STOP_ALL=true
      shift
      ;;
    -n|--name)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        PROJECT_NAME=$2
        STOP_ALL=false
        shift 2
      else
        log_error "오류: --name 인수 누락"
        show_usage
        exit 1
      fi
      ;;
    -l|--list)
      LIST_ONLY=true
      STOP_ALL=false
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

# 실행 중인 프로젝트 목록 표시
if [ "$LIST_ONLY" = true ]; then
  show_running_projects
  exit $?
fi

# 특정 프로젝트 중지
if [ -n "$PROJECT_NAME" ]; then
  stop_project "$PROJECT_NAME"
  exit $?
fi

# 모든 프로젝트 중지
if [ "$STOP_ALL" = true ]; then
  stop_all_projects
  exit $?
fi 