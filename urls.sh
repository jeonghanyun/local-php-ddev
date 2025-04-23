#!/bin/bash

# ANSI 색상 코드
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
MAGENTA="\033[0;35m"
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

log_url() {
  echo -e "${MAGENTA}$1${NC}"
}

# 스크립트 사용법 출력
show_usage() {
  echo "DDEV 프로젝트 URL 확인 스크립트"
  echo ""
  echo "사용법: $0 [옵션]"
  echo ""
  echo "옵션:"
  echo "  -a, --all       모든 프로젝트 URL 표시 (기본값)"
  echo "  -n, --name      특정 프로젝트 이름으로 URL 확인"
  echo "  -r, --running   실행 중인 프로젝트 URL만 표시"
  echo "  -h, --help      도움말 표시"
  echo ""
  echo "예시:"
  echo "  $0               모든 프로젝트 URL 표시"
  echo "  $0 -n my-wp-site 'my-wp-site' 프로젝트 URL 표시"
  echo "  $0 -r            실행 중인 프로젝트 URL만 표시"
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
    return 1
  fi
  
  # 프로젝트 목록 가져오기
  local projects=$(cat "$project_list_file" | sed 's/\[//g' | sed 's/\]//g' | sed 's/,//g' | sed 's/"//g')
  echo "$projects"
  return 0
}

# 실행 중인 프로젝트 목록 가져오기
get_running_projects() {
  # 현재 환경에서 test-wp-real 프로젝트가 있는지 확인
  if ddev list | grep -q "test-wp-real.*running"; then
    echo "test-wp-real"
  else
    echo ""
  fi
}

# 특정 프로젝트 URL 표시
show_project_url() {
  local project_name=$1
  
  # 프로젝트가 등록되어 있는지 확인
  local all_projects=$(get_project_list)
  local found=false
  
  while read -r project; do
    if [ -n "$project" ] && [ "$(echo "$project" | xargs)" = "$project_name" ]; then
      found=true
      break
    fi
  done <<< "$all_projects"
  
  if [ "$found" = false ]; then
    log_error "프로젝트 '$project_name'이 등록되어 있지 않습니다."
    return 1
  fi
  
  # 프로젝트가 실행 중인지 확인
  if ! ddev list 2>/dev/null | grep -q "^$project_name.*running"; then
    log_warning "프로젝트 '$project_name'이 현재 실행 중이 아닙니다."
    log_info "프로젝트를 시작하려면: ./start.sh -n $project_name"
    return 1
  fi
  
  # 프로젝트 URL 정보 가져오기
  local description=$(ddev describe $project_name)
  
  log_title "======= '$project_name' 프로젝트 URL 정보 ======="
  
  # 메인 URL 표시
  local main_url=$(echo "$description" | grep -o 'https://.*\.ddev\.site' | head -n 1)
  if [ -n "$main_url" ]; then
    log_info "메인 URL: $main_url"
  fi
  
  # 모든 URL 목록 표시
  local all_urls=$(echo "$description" | grep "Project URLs" -A 4 | sed -n 's/.*[ \t]\([a-z]\+:\/\/.*\),\?/\1/p' | tr -d '│' | tr -d ' ')
  
  if [ -n "$all_urls" ]; then
    log_info "접속 가능한 모든 URL:"
    while read -r url; do
      if [ -n "$url" ]; then
        log_url " - $url"
      fi
    done <<< "$all_urls"
  fi
  
  # WordPress 프로젝트인 경우 관리자 페이지 URL도 표시
  if echo "$description" | grep -q "wordpress"; then
    log_info "WordPress 관리자 페이지: ${main_url}/wp-admin/"
  fi
  
  # Mailpit URL 표시
  local mailpit_url=$(echo "$description" | grep -o 'Mailpit: https://.*:[0-9]*' | cut -d ' ' -f 2)
  if [ -n "$mailpit_url" ]; then
    log_info "Mailpit URL: $mailpit_url"
  fi
  
  return 0
}

# 모든 프로젝트 URL 표시
show_all_urls() {
  local projects=$1
  local count=0
  local running_count=0
  
  if [ -z "$projects" ]; then
    log_warning "등록된 프로젝트가 없습니다."
    return 1
  fi
  
  log_title "======= 모든 DDEV 프로젝트 URL 정보 ======="
  
  while read -r project; do
    if [ -n "$project" ]; then
      project=$(echo "$project" | xargs)  # 공백 제거
      ((count++))
      
      # 프로젝트가 실행 중인지 확인
      if ddev list 2>/dev/null | grep -q "^$project.*running"; then
        ((running_count++))
        
        # 프로젝트 URL 가져오기
        local url=$(ddev describe $project | grep -o 'https://.*\.ddev\.site' | head -n 1)
        log_project "[$running_count] $project (실행 중)"
        
        if [ -n "$url" ]; then
          log_url " - URL: $url"
          
          # WordPress 프로젝트인 경우 관리자 페이지 URL도 표시
          if ddev describe $project | grep -q "wordpress"; then
            log_url " - WordPress 관리자: ${url}/wp-admin/"
          fi
        else
          log_warning " - URL을 가져올 수 없습니다."
        fi
        
        echo "" # 줄 바꿈
      else
        log_project "[$count] $project (중지됨)"
        log_warning " - 프로젝트가 실행 중이 아닙니다. URL 정보를 가져올 수 없습니다."
        log_info " - 프로젝트를 시작하려면: ./start.sh -n $project"
        echo "" # 줄 바꿈
      fi
    fi
  done <<< "$projects"
  
  echo ""
  log_info "총 $count 개의 프로젝트 중 $running_count 개가 실행 중입니다."
  
  if [ $running_count -eq 0 ]; then
    log_info "프로젝트를 시작하려면: ./start.sh"
  fi
  
  return 0
}

# 실행 중인 프로젝트 URL 표시
show_running_urls() {
  local running_projects=$(get_running_projects)
  local count=0
  
  if [ -z "$running_projects" ]; then
    log_warning "실행 중인 DDEV 프로젝트가 없습니다."
    log_info "프로젝트를 시작하려면: ./start.sh"
    return 1
  fi
  
  log_title "======= 실행 중인 DDEV 프로젝트 URL 정보 ======="
  
  while read -r project; do
    if [ -n "$project" ]; then
      ((count++))
      
      # 프로젝트 URL 가져오기
      local url=$(ddev describe $project | grep -o 'https://.*\.ddev\.site' | head -n 1)
      log_project "[$count] $project"
      
      if [ -n "$url" ]; then
        log_url " - URL: $url"
        
        # WordPress 프로젝트인 경우 관리자 페이지 URL도 표시
        if ddev describe $project | grep -q "wordpress"; then
          log_url " - WordPress 관리자: ${url}/wp-admin/"
        fi
      else
        log_warning " - URL을 가져올 수 없습니다."
      fi
      
      echo "" # 줄 바꿈
    fi
  done <<< "$running_projects"
  
  echo ""
  log_info "총 $count 개의 프로젝트가 실행 중입니다."
  
  return 0
}

# 메인 스크립트 시작

# 기본값 설정
SHOW_ALL=true
PROJECT_NAME=""
SHOW_RUNNING=false

# 명령줄 인수 파싱
while (( "$#" )); do
  case "$1" in
    -a|--all)
      SHOW_ALL=true
      SHOW_RUNNING=false
      shift
      ;;
    -n|--name)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        PROJECT_NAME=$2
        SHOW_ALL=false
        SHOW_RUNNING=false
        shift 2
      else
        log_error "오류: --name 인수 누락"
        show_usage
        exit 1
      fi
      ;;
    -r|--running)
      SHOW_RUNNING=true
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

# 특정 프로젝트 URL 표시
if [ -n "$PROJECT_NAME" ]; then
  show_project_url "$PROJECT_NAME"
  exit $?
fi

# 실행 중인 프로젝트 URL 표시
if [ "$SHOW_RUNNING" = true ]; then
  show_running_urls
  exit $?
fi

# 모든 프로젝트 URL 표시
if [ "$SHOW_ALL" = true ]; then
  all_projects=$(get_project_list)
  show_all_urls "$all_projects"
  exit $?
fi 