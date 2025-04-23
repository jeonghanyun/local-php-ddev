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
DIRECTORIES_BACKUPS_DIR="$BACKUPS_DIR/directories"
PROJECT_DIR="$SCRIPT_DIR/ddev-projects"

# 사용법 출력
show_usage() {
  echo "DDEV 프로젝트 백업 스크립트"
  echo ""
  echo "사용법: $0 [옵션] [프로젝트명...]"
  echo ""
  echo "옵션:"
  echo "  -a, --all        모든 프로젝트 백업"
  echo "  -d, --db         데이터베이스만 백업 (기본: 데이터베이스와 디렉토리 모두 백업)"
  echo "  -c, --code       프로젝트 코드만 백업 (기본: 데이터베이스와 디렉토리 모두 백업)"
  echo "  -y, --yes        모든 확인 질문에 자동으로 '예' 응답"
  echo "  -h, --help       도움말 표시"
  echo ""
  echo "예시:"
  echo "  $0 project1 project2      # 지정된 프로젝트 백업"
  echo "  $0 --all                  # 모든 프로젝트 백업"
  echo "  $0 --all --db             # 모든 프로젝트의 데이터베이스만 백업"
  echo "  $0 --all --code           # 모든 프로젝트의 코드만 백업"
  echo "  $0 project1 --yes         # 확인 없이 project1 백업"
}

# 모든 프로젝트 목록 가져오기
get_all_projects() {
  # project-list.json 파일 확인
  if [ ! -f "$PROJECT_LIST_FILE" ]; then
    log_warning "프로젝트 목록 파일을 찾을 수 없습니다: $PROJECT_LIST_FILE" >&2
    log_info "새 프로젝트 목록 파일을 생성합니다." >&2
    mkdir -p "$PROJECT_DIR"
    echo '[]' > "$PROJECT_LIST_FILE"
    return 1
  fi
  
  # 프로젝트 목록 가져오기
  local projects_json=$(cat "$PROJECT_LIST_FILE")
  
  # 빈 목록 확인
  if [ "$projects_json" == "[]" ]; then
    log_info "설치된 프로젝트가 없습니다." >&2
    return 1
  fi
  
  # JSON 배열에서 각 프로젝트 이름을 추출
  echo "$projects_json" | sed 's/\[//g' | sed 's/\]//g' | sed 's/,//g' | sed 's/"//g'
  return 0
}

# 프로젝트 데이터베이스 백업
backup_project_db() {
  local project_name=$1
  
  # DDEV 프로젝트가 존재하는지 확인
  if ! ddev describe "$project_name" &>/dev/null; then
    log_warning "프로젝트 '$project_name'는 DDEV에 없습니다. 데이터베이스 백업을 건너뜁니다."
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

# 프로젝트 디렉토리 백업
backup_project_dir() {
  local project_name=$1
  local project_dir="$PROJECT_DIR/$project_name"
  
  # 프로젝트 디렉토리 확인
  if [ ! -d "$project_dir" ]; then
    log_warning "프로젝트 디렉토리가 존재하지 않습니다: $project_dir"
    return 0
  fi
  
  # 백업 디렉토리 생성
  mkdir -p "$DIRECTORIES_BACKUPS_DIR"
  
  # 날짜 형식의 타임스탬프
  local date_suffix=$(date +"%Y%m%d_%H%M%S")
  local backup_file="$DIRECTORIES_BACKUPS_DIR/${project_name}_dir_backup_$date_suffix.tar.gz"
  
  log_info "프로젝트 디렉토리 '$project_name' 압축 백업 중..."
  
  # 프로젝트 디렉토리 압축
  if tar -czf "$backup_file" -C "$PROJECT_DIR" "$project_name"; then
    log_info "프로젝트 디렉토리 백업 생성: $backup_file"
    return 0
  else
    log_warning "프로젝트 디렉토리 백업 생성 실패: $project_name"
    return 1
  fi
}

# 백업 프로젝트
backup_project() {
  local project_name=$1
  local backup_db=$2
  local backup_code=$3
  
  log_info "프로젝트 '$project_name' 백업 시작..."
  
  # 데이터베이스 백업
  if [ "$backup_db" = "true" ]; then
    backup_project_db "$project_name"
  fi
  
  # 디렉토리 백업
  if [ "$backup_code" = "true" ]; then
    backup_project_dir "$project_name"
  fi
  
  log_info "프로젝트 '$project_name' 백업 완료"
}

# 메인 스크립트 시작
BACKUP_ALL="false"
BACKUP_DB="true"
BACKUP_CODE="true"
AUTO_YES="false"
PROJECTS_TO_BACKUP=()

# 명령줄 인수 파싱
while (( "$#" )); do
  case "$1" in
    -a|--all)
      BACKUP_ALL="true"
      shift
      ;;
    -d|--db)
      BACKUP_DB="true"
      BACKUP_CODE="false"
      shift
      ;;
    -c|--code)
      BACKUP_DB="false"
      BACKUP_CODE="true"
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
    *) # 프로젝트 이름들
      PROJECTS_TO_BACKUP+=("$1")
      shift
      ;;
  esac
done

# DDEV가 설치되어 있는지 확인
if ! command -v ddev &> /dev/null; then
  log_error "DDEV가 설치되어 있지 않습니다. 이 스크립트를 실행하려면 DDEV가 필요합니다."
  exit 1
fi

# 백업 옵션 확인 메시지
if [ "$BACKUP_DB" = "true" ] && [ "$BACKUP_CODE" = "true" ]; then
  BACKUP_TYPE="데이터베이스와 코드"
elif [ "$BACKUP_DB" = "true" ]; then
  BACKUP_TYPE="데이터베이스만"
elif [ "$BACKUP_CODE" = "true" ]; then
  BACKUP_TYPE="코드만"
else
  log_error "백업할 항목이 선택되지 않았습니다."
  exit 1
fi

# 모든 프로젝트 백업 선택 시
if [ "$BACKUP_ALL" = "true" ]; then
  # 프로젝트 목록 가져오기
  PROJECTS_TO_BACKUP=($(get_all_projects))
  
  # 가져온 프로젝트가 없는 경우
  if [ ${#PROJECTS_TO_BACKUP[@]} -eq 0 ]; then
    log_error "백업할 프로젝트가 없습니다."
    exit 1
  fi
fi

# 백업할 프로젝트가 지정되지 않은 경우
if [ ${#PROJECTS_TO_BACKUP[@]} -eq 0 ]; then
  log_error "백업할 프로젝트를 지정하거나 --all 옵션을 사용하세요."
  show_usage
  exit 1
fi

# 백업 디렉토리 생성
mkdir -p "$BACKUPS_DIR"
mkdir -p "$DIRECTORIES_BACKUPS_DIR"

# 백업할 프로젝트 목록 표시
log_info "다음 프로젝트들을 백업합니다 ($BACKUP_TYPE):"
for i in "${!PROJECTS_TO_BACKUP[@]}"; do
  log_info "  $((i+1)). ${PROJECTS_TO_BACKUP[$i]}"
done

# 사용자 확인 (auto_yes가 true가 아닌 경우)
if [ "$AUTO_YES" != "true" ]; then
  log_warning "백업을 진행하시겠습니까? (y/n)"
  read -r confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    log_info "백업이 취소되었습니다."
    exit 0
  fi
fi

# 백업 시작
log_info "백업 시작..."
log_info "백업 위치: $BACKUPS_DIR (데이터베이스), $DIRECTORIES_BACKUPS_DIR (코드)"

# 프로젝트 개수 계산
TOTAL_PROJECTS=${#PROJECTS_TO_BACKUP[@]}
CURRENT=1

# 각 프로젝트 백업
for project in "${PROJECTS_TO_BACKUP[@]}"; do
  log_info "[$CURRENT/$TOTAL_PROJECTS] 프로젝트 '$project' 백업 중..."
  backup_project "$project" "$BACKUP_DB" "$BACKUP_CODE"
  CURRENT=$((CURRENT + 1))
done

log_info "모든 백업이 완료되었습니다."
log_info "백업된 프로젝트 수: $TOTAL_PROJECTS"
log_info "백업 디렉토리: $BACKUPS_DIR (데이터베이스), $DIRECTORIES_BACKUPS_DIR (코드)" 