#!/bin/bash

# ANSI 색상 코드
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
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

# 스크립트 디렉토리 가져오기
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_LIST_FILE="$SCRIPT_DIR/ddev-projects/project-list.json"
BACKUPS_DIR="$SCRIPT_DIR/backups"
PROJECT_DIR="$SCRIPT_DIR/ddev-projects"

# 사용법 출력
show_usage() {
  echo "DDEV 전체 프로젝트 정리 스크립트"
  echo ""
  echo "사용법: $0 [옵션]"
  echo ""
  echo "옵션:"
  echo "  -f, --force      확인 없이 강제 삭제"
  echo "  -b, --backup     삭제 전 모든 프로젝트 데이터베이스 백업"
  echo "  -y, --yes        모든 확인 질문에 자동으로 '예' 응답"
  echo "  -h, --help       도움말 표시"
  echo ""
  echo "예시:"
  echo "  $0               # 대화형 모드"
  echo "  $0 --force       # 확인 없이 강제 삭제"
  echo "  $0 --backup      # 백업 생성 후 삭제"
  echo "  $0 -f -b         # 백업 생성 후 강제 삭제"
}

# 모든 프로젝트 목록 가져오기
get_all_projects() {
  # project-list.json 파일 확인
  if [ ! -f "$PROJECT_LIST_FILE" ]; then
    log_warning "프로젝트 목록 파일을 찾을 수 없습니다: $PROJECT_LIST_FILE"
    log_info "새 프로젝트 목록 파일을 생성합니다."
    mkdir -p "$PROJECT_DIR"
    echo '[]' > "$PROJECT_LIST_FILE"
    return 0
  fi
  
  # 프로젝트 목록 가져오기
  local projects_json=$(cat "$PROJECT_LIST_FILE")
  
  # 빈 목록 확인
  if [ "$projects_json" == "[]" ]; then
    log_info "설치된 프로젝트가 없습니다."
    return 0
  fi
  
  # JSON 배열에서 각 프로젝트 이름을 추출
  echo "$projects_json" | sed 's/\[//g' | sed 's/\]//g' | sed 's/,//g' | sed 's/"//g'
}

# 프로젝트 백업
backup_project() {
  local project_name=$1
  
  # DDEV 프로젝트가 존재하는지 확인
  if ! ddev describe "$project_name" &>/dev/null; then
    log_warning "프로젝트 '$project_name'는 DDEV에 없습니다. 백업을 건너뜁니다."
    return 0
  fi
  
  # 백업 디렉토리 생성
  mkdir -p "$BACKUPS_DIR"
  
  # 프로젝트 상태 확인 후 시작 (프로젝트가 중지된 경우)
  if ! ddev describe "$project_name" | grep -q "running"; then
    log_info "프로젝트 '$project_name'를 시작합니다 (백업을 위해)..."
    ddev start "$project_name" &>/dev/null
  fi
  
  # 데이터베이스 백업
  log_info "프로젝트 '$project_name'의 데이터베이스를 백업 중..."
  local date_suffix=$(date +"%Y%m%d_%H%M%S")
  local backup_file="$BACKUPS_DIR/${project_name}_db_backup_$date_suffix.sql.gz"
  
  if ddev export-db -f "$backup_file" --database=db --gzip "$project_name" &>/dev/null; then
    log_info "데이터베이스 백업 생성: $backup_file"
    return 0
  else
    log_warning "데이터베이스 백업 생성 실패: $project_name"
    return 1
  fi
}

# 프로젝트 삭제
delete_project() {
  local project_name=$1
  local with_backup=$2
  
  # 백업 옵션이 활성화된 경우
  if [ "$with_backup" == "true" ]; then
    backup_project "$project_name"
  fi
  
  # DDEV 프로젝트 삭제
  if ddev describe "$project_name" &>/dev/null; then
    log_info "DDEV 프로젝트 '$project_name' 삭제 중..."
    
    # 먼저 프로젝트 unlink 시도
    log_info "프로젝트 '$project_name' 연결 해제 중..."
    ddev stop "$project_name" &>/dev/null
    
    if ddev config --project-name="$project_name" --project-type=php &>/dev/null; then
      log_info "프로젝트 '$project_name' 연결이 해제되었습니다."
    fi
    
    # 프로젝트 삭제
    ddev delete -O "$project_name" &>/dev/null
    
    if [ $? -eq 0 ]; then
      log_info "DDEV 프로젝트 '$project_name'가 삭제되었습니다."
    else
      log_error "DDEV 프로젝트 '$project_name' 삭제 중 오류가 발생했습니다."
    fi
  else
    log_warning "DDEV 프로젝트 '$project_name'를 찾을 수 없습니다."
  fi
  
  # 프로젝트 디렉토리 삭제
  local project_dir="$PROJECT_DIR/$project_name"
  if [ -d "$project_dir" ]; then
    log_info "프로젝트 디렉토리 삭제 중: $project_dir"
    rm -rf "$project_dir"
  fi
}

# 모든 프로젝트 삭제
cleanup_all_projects() {
  local force_delete=$1
  local with_backup=$2
  local auto_yes=$3
  
  # 사용자 확인
  if [ "$force_delete" != "true" ] && [ "$auto_yes" != "true" ]; then
    log_warning "이 작업은 모든 DDEV 프로젝트와 관련 파일을 삭제합니다. 계속하시겠습니까? (y/n)"
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      log_info "작업이 취소되었습니다."
      exit 0
    fi
  fi
  
  # 프로젝트 목록 가져오기
  local projects=$(get_all_projects)
  
  # 프로젝트가 없는 경우
  if [ -z "$projects" ]; then
    log_info "삭제할 프로젝트가 없습니다."
    
    # 프로젝트 디렉토리 정리 (project-list.json 제외)
    find "$PROJECT_DIR" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} \; 2>/dev/null
    
    # 빈 프로젝트 목록 생성
    echo '[]' > "$PROJECT_LIST_FILE"
    
    log_info "모든 프로젝트 디렉토리가 정리되었습니다."
    exit 0
  fi
  
  # 모든 프로젝트 삭제
  log_info "모든 프로젝트 삭제 시작..."
  
  # 백업 옵션이 활성화된 경우 안내
  if [ "$with_backup" == "true" ]; then
    log_info "각 프로젝트의 데이터베이스를 백업한 후 삭제합니다."
    log_info "백업 위치: $BACKUPS_DIR"
  fi
  
  # 프로젝트 개수 계산
  local total_projects=$(echo "$projects" | wc -w | xargs)
  local current=1
  
  # 각 프로젝트 삭제
  for project in $projects; do
    log_info "[$current/$total_projects] 프로젝트 '$project' 삭제 중..."
    delete_project "$project" "$with_backup"
    current=$((current + 1))
  done
  
  # ddev-projects 디렉토리에서 .gitkeep과 project-list.json을 제외한 모든 파일 삭제
  find "$PROJECT_DIR" -mindepth 1 -maxdepth 1 -not -name ".gitkeep" -not -name "project-list.json" -not -name "README.md" -exec rm -rf {} \; 2>/dev/null
  
  # 프로젝트 목록 초기화
  echo '[]' > "$PROJECT_LIST_FILE"
  
  log_info "모든 프로젝트 삭제가 완료되었습니다."
  log_info "프로젝트 목록이 초기화되었습니다."
}

# 메인 스크립트 시작
FORCE_DELETE="false"
WITH_BACKUP="false"
AUTO_YES="false"

# 명령줄 인수 파싱
while (( "$#" )); do
  case "$1" in
    -f|--force)
      FORCE_DELETE="true"
      shift
      ;;
    -b|--backup)
      WITH_BACKUP="true"
      shift
      ;;
    -y|--yes)
      AUTO_YES="true"
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

# DDEV가 설치되어 있는지 확인
if ! command -v ddev &> /dev/null; then
  log_error "DDEV가 설치되어 있지 않습니다. 이 스크립트를 실행하려면 DDEV가 필요합니다."
  exit 1
fi

# 모든 프로젝트 삭제 실행
cleanup_all_projects "$FORCE_DELETE" "$WITH_BACKUP" "$AUTO_YES" 