#!/bin/bash

# ANSI 색상 코드
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

# 관리자 권한 확인 함수
check_sudo_access() {
  log_info "관리자 권한 확인 중..."
  if sudo -n true 2>/dev/null; then
    log_info "관리자 권한이 있습니다."
    return 0
  else
    log_warning "이 스크립트는 프로젝트 삭제 시 관리자 권한이 필요합니다."
    log_info "비밀번호를 입력하세요:"
    if sudo -v; then
      log_info "관리자 권한이 확인되었습니다."
      # sudo 인증 시간 연장 (기본 15분)
      (while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &)
      return 0
    else
      log_error "관리자 권한을 얻지 못했습니다. 일부 기능이 제한될 수 있습니다."
      return 1
    fi
  fi
}

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

# 스크립트 디렉토리 가져오기
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_LIST_FILE="$SCRIPT_DIR/ddev-projects/project-list.json"

# 스크립트 사용법 출력
show_usage() {
  echo "DDEV 프로젝트 삭제 스크립트"
  echo ""
  echo "사용법: $0 [옵션]"
  echo ""
  echo "옵션:"
  echo "  -i, --interactive  대화형 모드 (기본값)"
  echo "  -n, --name         삭제할 프로젝트 이름 직접 지정"
  echo "  -f, --force        확인 없이 강제 삭제"
  echo "  -a, --all          모든 프로젝트 삭제"
  echo "  -u, --update       프로젝트 목록 파일 업데이트"
  echo "  -h, --help         도움말 표시"
  echo ""
  echo "참고:"
  echo "  - 프로젝트 삭제 시 관리자 권한(sudo)이 필요합니다."
  echo "  - 비밀번호를 요청할 수 있습니다."
  echo ""
  echo "예시:"
  echo "  $0                  # 대화형 모드"
  echo "  $0 --name my-project"
  echo "  $0 -n my-project -f # 강제 삭제"
  echo "  $0 -a              # 모든 프로젝트 삭제"
  echo "  $0 -u              # 프로젝트 목록 업데이트"
}

# 프로젝트 목록 파일 업데이트
update_project_list() {
  log_info "프로젝트 목록 파일을 업데이트합니다..."
  
  # 프로젝트 디렉토리 확인
  local projects_dir="$SCRIPT_DIR/ddev-projects"
  
  # 프로젝트 디렉토리 목록 가져오기 (숨김 파일 및 디렉토리 제외)
  local dirs=$(find "$projects_dir" -mindepth 1 -maxdepth 1 -type d -not -path "*/\.*" -exec basename {} \;)
  
  # JSON 배열 생성
  local json="["
  local first=true
  
  for dir in $dirs; do
    # .ddev 디렉토리 확인하여 실제 DDEV 프로젝트인지 검증
    if [ -d "$projects_dir/$dir/.ddev" ]; then
      if [ "$first" = true ]; then
        json+="\"$dir\""
        first=false
      else
        json+=", \"$dir\""
      fi
    fi
  done
  
  json+="]"
  
  # 새 목록 저장 전 이전 목록 백업
  if [ -f "$PROJECT_LIST_FILE" ]; then
    cp "$PROJECT_LIST_FILE" "${PROJECT_LIST_FILE}.bak"
  fi
  
  # 새 목록 파일 저장
  echo "$json" > "$PROJECT_LIST_FILE"
  
  log_info "프로젝트 목록 파일이 업데이트되었습니다: $PROJECT_LIST_FILE"
  log_info "등록된 프로젝트 목록:"
  cat "$PROJECT_LIST_FILE"
  
  return 0
}

# 프로젝트 목록 표시 및 번호 입력 처리
list_and_select_project() {
  # project-list.json 파일 확인
  if [ ! -f "$PROJECT_LIST_FILE" ]; then
    log_info "프로젝트 목록 파일을 생성합니다."
    update_project_list
  fi
  
  # 프로젝트 목록 가져오기
  local projects_json=$(cat "$PROJECT_LIST_FILE")
  
  # 빈 목록 확인
  if [ "$projects_json" == "[]" ]; then
    log_info "설치된 프로젝트가 없습니다."
    exit 0
  fi
  
  # 실제 디렉토리 확인하여 목록 일치 여부 검사
  local projects_dir="$SCRIPT_DIR/ddev-projects"
  local actual_dirs=$(find "$projects_dir" -mindepth 1 -maxdepth 1 -type d -not -path "*/\.*" -exec basename {} \; | sort)
  local json_projects=$(echo "$projects_json" | tr -d '[]"' | tr ',' ' ' | tr -s ' ' | sort)
  
  # 목록이 실제 디렉토리와 일치하지 않는 경우 자동 업데이트
  if [ "$actual_dirs" != "$json_projects" ]; then
    log_warning "프로젝트 목록 파일이 실제 디렉토리와 일치하지 않습니다."
    log_info "프로젝트 목록 파일을 자동으로 업데이트합니다."
    update_project_list
    # 업데이트된 JSON 다시 읽기
    projects_json=$(cat "$PROJECT_LIST_FILE")
  fi
  
  log_info "설치된 DDEV 프로젝트 목록:"
  echo "-------------------------------------"
  
  # JSON 배열에서 각 프로젝트 이름을 추출하여 표시
  # project-list.json 형식: ["project1", "project2", ...]
  local projects=$(echo "$projects_json" | sed 's/\[//g' | sed 's/\]//g' | sed 's/,//g' | sed 's/"//g')
  
  # 프로젝트 배열 생성
  local project_array=()
  
  local count=1
  for project in $projects; do
    # 프로젝트 디렉토리 확인
    local project_dir="$SCRIPT_DIR/ddev-projects/$project"
    local status="[존재함]"
    
    if [ ! -d "$project_dir" ]; then
      status="[디렉토리 없음]"
    fi
    
    # DDEV 상태 확인
    if ddev describe "$project" &>/dev/null; then
      local ddev_status=$(ddev describe "$project" | grep -oE "running|stopped" | head -n 1)
      if [ "$ddev_status" == "running" ]; then
        status="$status [실행 중]"
      else
        status="$status [중지됨]"
      fi
    else
      status="$status [DDEV 설정 없음]"
    fi
    
    echo "$count. $project $status"
    
    # 프로젝트 URL 표시 (DDEV가 실행 중인 경우)
    if ddev describe "$project" &>/dev/null; then
      local url=$(ddev describe "$project" | grep -o 'https://.*\.ddev\.site' | head -n 1)
      if [ -n "$url" ]; then
        echo "   URL: $url"
      fi
    fi
    
    # 배열에 프로젝트 추가
    project_array+=("$project")
    
    count=$((count + 1))
  done
  
  echo "-------------------------------------"
  echo "a. 모든 프로젝트 삭제"
  echo "u. 프로젝트 목록 업데이트"
  echo "0. 취소"
  echo "-------------------------------------"
  
  # 사용자 입력 받기
  local selection
  
  # -t 옵션은 입력 시간제한을 설정합니다 (여기서는 3600초 = 1시간)
  read -t 3600 -p "삭제할 프로젝트 번호 또는 작업을 선택하세요 (a: 모든 프로젝트 삭제, u: 목록 업데이트): " selection
  
  # 입력이 "a" 또는 "A"인 경우 모든 프로젝트 삭제
  if [[ "$selection" == "a" || "$selection" == "A" ]]; then
    cleanup_all_projects "$FORCE_DELETE"
    return
  fi
  
  # 입력이 "u" 또는 "U"인 경우 목록 업데이트
  if [[ "$selection" == "u" || "$selection" == "U" ]]; then
    update_project_list
    # 다시 목록 표시
    list_and_select_project
    return
  fi
  
  # 입력 검증
  if [[ ! "$selection" =~ ^[0-9]+$ ]]; then
    log_error "숫자, 'a', 또는 'u'만 입력하세요."
    exit 1
  fi
  
  # 취소 옵션
  if [ "$selection" -eq 0 ]; then
    log_info "작업을 취소했습니다."
    exit 0
  fi
  
  # 범위 확인
  if [ "$selection" -lt 1 ] || [ "$selection" -gt "${#project_array[@]}" ]; then
    log_error "유효하지 않은 번호입니다: $selection"
    exit 1
  fi
  
  # 인덱스는 0부터 시작하므로 1을 빼줍니다
  local index=$((selection - 1))
  local selected_project="${project_array[$index]}"
  
  log_info "선택한 프로젝트: $selected_project"
  
  # 선택한 프로젝트 삭제
  cleanup_project "$selected_project" "$FORCE_DELETE"
}

# 모든 프로젝트 삭제 기능
cleanup_all_projects() {
  local force_delete=$1
  
  # 관리자 권한 확인
  if ! sudo -n true 2>/dev/null; then
    log_warning "관리자 권한이 필요합니다. 비밀번호를 입력하세요:"
    sudo -v || log_warning "관리자 권한을 얻지 못했습니다. 일부 파일이 삭제되지 않을 수 있습니다."
  fi
  
  # project-list.json 파일 확인
  if [ ! -f "$PROJECT_LIST_FILE" ]; then
    log_error "프로젝트 목록 파일을 찾을 수 없습니다: $PROJECT_LIST_FILE"
    exit 1
  fi
  
  # 프로젝트 목록 가져오기
  local projects_json=$(cat "$PROJECT_LIST_FILE")
  
  # 빈 목록 확인
  if [ "$projects_json" == "[]" ]; then
    log_info "설치된 프로젝트가 없습니다."
    exit 0
  fi
  
  # JSON 배열에서 각 프로젝트 이름을 추출
  local projects=$(echo "$projects_json" | sed 's/\[//g' | sed 's/\]//g' | sed 's/,//g' | sed 's/"//g')
  
  # 사용자 확인 (강제 삭제가 아닐 경우)
  if [ "$force_delete" != "true" ]; then
    log_warning "정말로 모든 프로젝트를 완전히 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다. (y/n)"
    read -t 3600 -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      log_info "프로젝트 삭제를 취소했습니다."
      exit 0
    fi
  fi
  
  log_info "모든 프로젝트 삭제를 시작합니다..."
  
  # 모든 프로젝트 순회하면서 삭제
  for project in $projects; do
    log_info "프로젝트 '$project' 삭제 중..."
    cleanup_project "$project" "true"  # 개별 확인 없이 강제 삭제
  done
  
  # 프로젝트 목록 초기화
  echo "[]" > "$PROJECT_LIST_FILE"
  
  log_info "모든 프로젝트가 성공적으로 삭제되었습니다."
}

# 프로젝트 삭제 기능
cleanup_project() {
  local project_name=$1
  local force_delete=$2
  
  # 프로젝트 이름 필수
  if [ -z "$project_name" ]; then
    log_error "삭제할 프로젝트 이름을 지정해야 합니다."
    exit 1
  fi
  
  # 프로젝트 디렉토리 설정
  local project_dir="$SCRIPT_DIR/ddev-projects/$project_name"
  
  # 프로젝트 확인
  if ! ddev describe "$project_name" &>/dev/null; then
    log_warning "DDEV 프로젝트 '$project_name'를 찾을 수 없습니다."
    
    # 디렉토리 확인
    if [ ! -d "$project_dir" ]; then
      log_error "프로젝트 디렉토리도 존재하지 않습니다: $project_dir"
      
      # 프로젝트 목록 파일 확인
      if [ -f "$PROJECT_LIST_FILE" ] && grep -q "\"$project_name\"" "$PROJECT_LIST_FILE"; then
        log_warning "프로젝트가 목록에만 존재합니다. 목록에서 제거할까요? (y/n)"
        
        # 강제 삭제가 아닐 경우 확인
        if [ "$force_delete" != "true" ]; then
          read -t 3600 -r confirm
          if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            log_info "작업을 취소했습니다."
            exit 0
          fi
        fi
        
        # 목록에서 제거
        local projects_json=$(cat "$PROJECT_LIST_FILE")
        local updated_projects=$(echo "$projects_json" | sed 's/"'"$project_name"'"//g' | sed 's/, ,/,/g' | sed 's/\[,/\[/g' | sed 's/,\]/\]/g')
        echo "$updated_projects" > "$PROJECT_LIST_FILE"
        log_info "프로젝트 '$project_name'를 목록에서 제거했습니다."
        
        # 사용자에게 계속 진행할지 묻기
        log_info "계속 진행하시겠습니까? (y/n)"
        read -t 3600 -r continue_confirm
        if [[ ! "$continue_confirm" =~ ^[Yy]$ ]]; then
          log_info "스크립트를 종료합니다."
          exit 0
        fi
      else
        log_error "프로젝트 '$project_name'는 존재하지 않습니다."
        exit 1
      fi
    fi
  fi
  
  # 사용자 확인 (강제 삭제가 아닐 경우)
  if [ "$force_delete" != "true" ]; then
    log_warning "정말로 프로젝트 '$project_name'를 완전히 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다. (y/n)"
    read -t 3600 -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      log_info "프로젝트 삭제를 취소했습니다."
      exit 0
    fi
  fi
  
  log_info "프로젝트 '$project_name' 삭제를 시작합니다..."
  
  # 1. DDEV 프로젝트 중지 및 삭제
  if ddev describe "$project_name" &>/dev/null; then
    log_info "DDEV 프로젝트 정리 중..."
    
    # 프로젝트 상태 확인 후 중지
    if ddev describe "$project_name" | grep -q "running"; then
      log_info "프로젝트 중지 중..."
      ddev stop "$project_name"
    fi
    
    # 프로젝트 데이터베이스 스냅샷 생성 (백업)
    log_info "데이터베이스 백업 생성 중..."
    local backup_dir="$SCRIPT_DIR/backups"
    mkdir -p "$backup_dir"
    local date_suffix=$(date +"%Y%m%d_%H%M%S")
    local backup_file="$backup_dir/${project_name}_db_backup_$date_suffix.sql.gz"
    
    if ddev export-db -f "$backup_file" --database=db --gzip "$project_name" &>/dev/null; then
      log_info "데이터베이스 백업이 생성되었습니다: $backup_file"
    else
      log_warning "데이터베이스 백업 생성에 실패했습니다."
    fi
    
    # 프로젝트 삭제 (컨테이너, 볼륨 등 모두 삭제)
    log_info "DDEV 프로젝트 삭제 중..."
    ddev delete -O "$project_name"
  else
    log_warning "DDEV 프로젝트 '$project_name'를 찾을 수 없습니다. 파일만 삭제합니다."
  fi
  
  # 2. 프로젝트 디렉토리 삭제
  if [ -d "$project_dir" ]; then
    log_info "프로젝트 디렉토리 삭제 중: $project_dir"
    # 관리자 권한으로 디렉토리 삭제 시도
    log_info "관리자 권한으로 삭제를 시도합니다. 비밀번호를 입력하세요."
    if sudo rm -rf "$project_dir"; then
      log_info "프로젝트 디렉토리가 성공적으로 삭제되었습니다."
    else
      log_error "디렉토리 삭제에 실패했습니다. 권한을 확인하세요."
      # 삭제 성공 여부 확인
      if [ -d "$project_dir" ]; then
        log_warning "디렉토리가 여전히 존재합니다. 수동으로 삭제하세요: $project_dir"
      fi
    fi
  else
    log_warning "프로젝트 디렉토리가 없습니다: $project_dir"
  fi
  
  # 3. 프로젝트 목록에서 제거
  if [ -f "$PROJECT_LIST_FILE" ] && grep -q "\"$project_name\"" "$PROJECT_LIST_FILE"; then
    log_info "프로젝트를 목록에서 제거합니다..."
    
    # 목록에서 프로젝트 이름 제거
    local projects_json=$(cat "$PROJECT_LIST_FILE")
    local updated_projects=$(echo "$projects_json" | sed 's/"'"$project_name"'"//g' | sed 's/, ,/,/g' | sed 's/\[,/\[/g' | sed 's/,\]/\]/g')
    echo "$updated_projects" > "$PROJECT_LIST_FILE"
  fi
  
  # 4. 호스트 항목 정리 (선택적)
  if grep -q "$project_name.ddev.site" /etc/hosts 2>/dev/null; then
    log_warning "/etc/hosts 파일에 프로젝트 항목이 남아있을 수 있습니다."
    log_warning "필요한 경우 관리자 권한으로 수동 정리가 필요합니다."
  fi
  
  log_info "프로젝트 '$project_name'가 성공적으로 삭제되었습니다."
  log_info "백업 디렉토리를 확인하세요: $SCRIPT_DIR/backups"
  
  # 다음 작업 선택 옵션 제공
  log_info "다음 작업을 선택하세요:"
  echo "-------------------------------------"
  echo "1. 다른 프로젝트 삭제"
  echo "2. 프로젝트 목록 업데이트"
  echo "0. 종료"
  echo "-------------------------------------"
  read -t 3600 -p "선택: " next_action
  
  case $next_action in
    1)
      # 대화형 모드로 다시 실행
      list_and_select_project
      ;;
    2)
      # 목록 업데이트 후 대화형 모드
      update_project_list
      list_and_select_project
      ;;
    0|*)
      log_info "스크립트를 종료합니다."
      exit 0
      ;;
  esac
}

# 메인 스크립트 시작

# 관리자 권한 확인
check_sudo_access

# 기본값 설정
PROJECT_NAME=""
FORCE_DELETE="false"
INTERACTIVE="true"
UPDATE_ONLY="false"
DELETE_ALL="false"

# 명령줄 인수 파싱
while (( "$#" )); do
  case "$1" in
    -i|--interactive)
      INTERACTIVE="true"
      shift
      ;;
    -n|--name)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        PROJECT_NAME=$2
        INTERACTIVE="false"
        shift 2
      else
        log_error "오류: --name 인수 누락"
        show_usage
        exit 1
      fi
      ;;
    -f|--force)
      FORCE_DELETE="true"
      shift
      ;;
    -a|--all)
      DELETE_ALL="true"
      INTERACTIVE="false"
      shift
      ;;
    -u|--update)
      UPDATE_ONLY="true"
      INTERACTIVE="false"
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

# 목록 업데이트만 수행
if [ "$UPDATE_ONLY" == "true" ]; then
  update_project_list
  exit 0
fi

# 모든 프로젝트 삭제
if [ "$DELETE_ALL" == "true" ]; then
  cleanup_all_projects "$FORCE_DELETE"
  exit 0
fi

# 작업 모드 결정
if [ "$INTERACTIVE" == "true" ]; then
  # 대화형 모드: 목록 표시 및 번호 입력
  list_and_select_project
else
  # 직접 지정 모드: 입력된 프로젝트 이름으로 삭제
  if [ -z "$PROJECT_NAME" ]; then
    log_error "삭제할 프로젝트 이름을 지정해야 합니다."
    show_usage
    exit 1
  fi
  cleanup_project "$PROJECT_NAME" "$FORCE_DELETE"
fi 