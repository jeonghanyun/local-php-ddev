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
  echo "DDEV 프로젝트 실행 스크립트"
  echo ""
  echo "사용법: $0 [옵션]"
  echo ""
  echo "옵션:"
  echo "  -a, --all       모든 프로젝트 시작 (기본값)"
  echo "  -n, --name      특정 프로젝트 이름으로 시작"
  echo "  -l, --list      실행 가능한 프로젝트 목록만 표시"
  echo "  -h, --help      도움말 표시"
  echo ""
  echo "예시:"
  echo "  $0               모든 프로젝트 시작"
  echo "  $0 -n my-wp-site 'my-wp-site' 프로젝트만 시작"
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

# Docker 실행 확인
check_docker() {
  if ! docker info &> /dev/null; then
    log_error "Docker가 실행되고 있지 않습니다. Docker를 시작한 후 다시 시도해주세요."
    exit 1
  fi
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

# 프로젝트 목록 표시
show_project_list() {
  local projects=$(get_project_list)
  
  if [ -z "$projects" ]; then
    log_error "등록된 프로젝트가 없습니다."
    log_info "프로젝트를 먼저 설치하세요: ./install.sh -t [wordpress|laravel] -n 프로젝트이름"
    return 1
  fi
  
  log_title "======= 실행 가능한 프로젝트 목록 ======="
  local count=0
  
  while read -r project; do
    if [ -n "$project" ]; then
      project=$(echo "$project" | xargs)  # 공백 제거
      
      # 프로젝트 경로 확인
      local script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
      local project_path="$script_dir/ddev-projects/$project"
      
      if [ -d "$project_path" ]; then
        # 실행 상태 확인
        local status=""
        if ddev list 2>/dev/null | grep -q "^$project.*running"; then
          status="(실행 중)"
        else
          status="(중지됨)"
        fi
        echo " - $project $status"
      else
        echo " - $project (디렉토리 없음)"
      fi
      
      ((count++))
    fi
  done <<< "$projects"
  
  echo ""
  log_info "총 $count 개의 프로젝트가 등록되어 있습니다."
  log_info "프로젝트 시작 명령어: $0 -n 프로젝트이름"
  
  return 0
}

# 특정 프로젝트 시작
start_project() {
  local project_name=$1
  local projects=$(get_project_list)
  local found=false
  
  # 프로젝트가 목록에 있는지 확인
  while read -r project; do
    if [ -n "$project" ] && [ "$(echo "$project" | xargs)" = "$project_name" ]; then
      found=true
      break
    fi
  done <<< "$projects"
  
  if [ "$found" = false ]; then
    log_error "프로젝트 '$project_name'이 등록되어 있지 않습니다."
    log_info "등록된 프로젝트 목록 확인: $0 -l"
    return 1
  fi
  
  # 프로젝트 경로 확인
  local script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
  local project_path="$script_dir/ddev-projects/$project_name"
  
  if [ ! -d "$project_path" ]; then
    log_error "프로젝트 디렉토리가 존재하지 않습니다: $project_path"
    return 1
  fi
  
  # 프로젝트가 이미 실행 중인지 확인
  if ddev list 2>/dev/null | grep -q "^$project_name.*running"; then
    log_warning "프로젝트 '$project_name'이 이미 실행 중입니다."
    return 0
  fi
  
  log_info "프로젝트 '$project_name' 시작 중..."
  
  # 프로젝트 시작
  cd "$project_path" && ddev start
  
  if [ $? -ne 0 ]; then
    log_error "프로젝트 '$project_name' 시작에 실패했습니다."
    return 1
  fi
  
  # 프로젝트 URL 가져오기
  local url=$(ddev describe $project_name | grep -o 'https://.*\.ddev\.site' | head -n 1)
  
  if [ -n "$url" ]; then
    log_title "======= 프로젝트 '$project_name' 정보 ======="
    log_info "프로젝트 URL: $url"
    
    # WordPress 프로젝트인 경우 관리자 페이지 URL도 표시
    if ddev describe $project_name | grep -q "wordpress"; then
      log_info "WordPress 관리자: ${url}/wp-admin/"
    fi
    
    log_info "프로젝트 상태 확인: ./status.sh -n $project_name"
  fi
  
  return 0
}

# 모든 프로젝트 시작
start_all_projects() {
  local projects=$(get_project_list)
  local success_count=0
  local fail_count=0
  
  if [ -z "$projects" ]; then
    log_error "등록된 프로젝트가 없습니다."
    log_info "프로젝트를 먼저 설치하세요: ./install.sh -t [wordpress|laravel] -n 프로젝트이름"
    return 1
  fi
  
  log_title "======= 모든 프로젝트 시작 ======="
  
  while read -r project; do
    if [ -n "$project" ]; then
      project=$(echo "$project" | xargs)  # 공백 제거
      
      # 각 프로젝트 시작
      if start_project "$project"; then
        ((success_count++))
      else
        ((fail_count++))
      fi
      
      echo "" # 줄 바꿈
    fi
  done <<< "$projects"
  
  log_title "======= 프로젝트 시작 결과 ======="
  log_info "성공: $success_count 개, 실패: $fail_count 개"
  
  if [ $success_count -gt 0 ]; then
    log_info "프로젝트 상태 확인: ./status.sh"
  fi
  
  return 0
}

# 메인 스크립트 시작

# 기본값 설정
START_ALL=true
PROJECT_NAME=""
LIST_ONLY=false

# 명령줄 인수 파싱
while (( "$#" )); do
  case "$1" in
    -a|--all)
      START_ALL=true
      shift
      ;;
    -n|--name)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        PROJECT_NAME=$2
        START_ALL=false
        shift 2
      else
        log_error "오류: --name 인수 누락"
        show_usage
        exit 1
      fi
      ;;
    -l|--list)
      LIST_ONLY=true
      START_ALL=false
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
  exit $?
fi

# 특정 프로젝트 시작
if [ -n "$PROJECT_NAME" ]; then
  start_project "$PROJECT_NAME"
  exit $?
fi

# 모든 프로젝트 시작
if [ "$START_ALL" = true ]; then
  start_all_projects
  exit $?
fi 