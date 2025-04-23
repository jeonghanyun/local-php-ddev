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
BACKUPS_DIR="$SCRIPT_DIR/backups"
PROJECT_DIR="$SCRIPT_DIR/ddev-projects"
PROJECT_LIST_FILE="$PROJECT_DIR/project-list.json"

# 사용법 출력
show_usage() {
  echo "DDEV 백업 복원 스크립트"
  echo ""
  echo "사용법: $0 [옵션]"
  echo ""
  echo "옵션:"
  echo "  -f, --file       백업 파일 경로 [필수]"
  echo "  -n, --name       프로젝트 이름 [필수]"
  echo "  -t, --type       프로젝트 유형 (wordpress 또는 laravel, 기본값: wordpress)"
  echo "  -y, --yes        모든 확인 질문에 자동으로 '예' 응답"
  echo "  -h, --help       도움말 표시"
  echo ""
  echo "예시:"
  echo "  $0 --file backups/mysite_db_backup_20250424_123456.sql.gz --name mysite"
  echo "  $0 -f backups/mysite_db_backup_20250424_123456.sql.gz -n mysite -t laravel"
  echo "  $0 -f backups/mysite_db_backup_20250424_123456.sql.gz -n mysite -y"
}

# 백업 파일에서 프로젝트 이름 추출 (파일명에서 추정)
extract_project_name_from_file() {
  local backup_file="$1"
  local filename="$(basename "$backup_file")"
  
  # 파일명 형식이 project_db_backup_date.sql.gz인 경우
  if [[ "$filename" =~ (.*)_db_backup_ ]]; then
    local project_name="${BASH_REMATCH[1]}"
    echo "$project_name"
    return 0
  fi
  
  # 형식에 맞지 않는 경우
  return 1
}

# 백업 파일 목록 표시
list_backups() {
  if [ ! -d "$BACKUPS_DIR" ] || [ -z "$(ls -A "$BACKUPS_DIR" 2>/dev/null)" ]; then
    log_error "백업 파일이 존재하지 않습니다: $BACKUPS_DIR"
    return 1
  fi
  
  log_info "사용 가능한 백업 파일:"
  local count=1
  
  for backup_file in "$BACKUPS_DIR"/*.sql.gz; do
    if [ -f "$backup_file" ]; then
      local filename="$(basename "$backup_file")"
      local project_name=""
      
      # 파일명에서 프로젝트 이름 추출 시도
      if extract_project_name_from_file "$backup_file" > /dev/null; then
        project_name="$(extract_project_name_from_file "$backup_file")"
      fi
      
      # 파일 크기
      local file_size="$(du -h "$backup_file" | cut -f1)"
      
      # 파일 날짜
      local file_date="$(date -r "$backup_file" "+%Y-%m-%d %H:%M:%S")"
      
      # 프로젝트 이름이 추출된 경우
      if [ -n "$project_name" ]; then
        echo "  $count. $filename (프로젝트: $project_name, 크기: $file_size, 날짜: $file_date)"
      else
        echo "  $count. $filename (크기: $file_size, 날짜: $file_date)"
      fi
      
      count=$((count + 1))
    fi
  done
  
  return 0
}

# 프로젝트 설정 준비 (WordPress 또는 Laravel)
setup_project() {
  local project_name="$1"
  local project_type="$2"
  local project_dir="$PROJECT_DIR/$project_name"
  
  log_info "프로젝트 디렉토리 준비 중: $project_dir"
  
  # 프로젝트 디렉토리 생성
  mkdir -p "$project_dir"
  
  # 현재 디렉토리 저장
  local current_dir=$(pwd)
  
  # 프로젝트 디렉토리로 이동
  cd "$project_dir" || { log_error "디렉토리 $project_dir로 이동할 수 없습니다."; return 1; }
  
  # 기본 디렉토리 생성
  mkdir -p public
  
  # 프로젝트 타입에 따른 설정
  if [ "$project_type" == "wordpress" ]; then
    log_info "WordPress 프로젝트로 설정 중..."
    
    # DDEV 설정 파일 생성
    ddev config --project-name="$project_name" --project-type=wordpress --docroot=public --create-docroot
    
    # 임시 index 파일 생성
    echo "<?php // Restored WordPress Project" > public/index.php
    
  elif [ "$project_type" == "laravel" ]; then
    log_info "Laravel 프로젝트로 설정 중..."
    
    # DDEV 설정 파일 생성
    ddev config --project-name="$project_name" --project-type=laravel --docroot=public --create-docroot
    
    # 임시 index 파일 생성
    echo "<?php // Restored Laravel Project" > public/index.php
    
  else
    log_error "지원되지 않는 프로젝트 유형: $project_type"
    cd "$current_dir"
    return 1
  fi
  
  # 원래 디렉토리로 복귀
  cd "$current_dir"
  
  return 0
}

# 프로젝트를 project-list.json에 추가
add_to_project_list() {
  local project_name="$1"
  
  # project-list.json 파일이 없으면 생성
  if [ ! -f "$PROJECT_LIST_FILE" ]; then
    mkdir -p "$PROJECT_DIR"
    echo '[]' > "$PROJECT_LIST_FILE"
  fi
  
  # 현재 프로젝트 목록 가져오기
  local projects=$(cat "$PROJECT_LIST_FILE")
  
  # 프로젝트 이름이 이미 목록에 있는지 확인
  if echo "$projects" | grep -q "\"$project_name\""; then
    log_info "프로젝트 '$project_name'는 이미 프로젝트 목록에 있습니다."
  else
    # 빈 목록인 경우
    if [ "$projects" = "[]" ]; then
      local updated_projects="[\"$project_name\"]"
    else
      # 목록에 추가
      local updated_projects=$(echo "$projects" | sed 's/\]/, "'"$project_name"'"&/')
    fi
    
    echo "$updated_projects" > "$PROJECT_LIST_FILE"
    log_info "프로젝트 '$project_name'를 프로젝트 목록에 추가했습니다."
  fi
}

# 백업 복원
restore_backup() {
  local backup_file="$1"
  local project_name="$2"
  local project_type="$3"
  local auto_yes="$4"
  
  # 백업 파일 확인
  if [ ! -f "$backup_file" ]; then
    log_error "백업 파일을 찾을 수 없습니다: $backup_file"
    return 1
  fi
  
  # 사용자 확인 (auto_yes가 true가 아닌 경우)
  if [ "$auto_yes" != "true" ]; then
    log_warning "프로젝트 '$project_name'에 백업 파일을 복원합니다. 계속하시겠습니까? (y/n)"
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      log_info "복원 작업이 취소되었습니다."
      return 0
    fi
  fi
  
  # 이미 존재하는 프로젝트 확인
  if ddev describe "$project_name" &>/dev/null; then
    log_warning "DDEV 프로젝트 '$project_name'가 이미 존재합니다."
    
    if [ "$auto_yes" != "true" ]; then
      log_warning "기존 프로젝트를 덮어쓰시겠습니까? (y/n)"
      read -r confirm
      if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_info "복원 작업이 취소되었습니다."
        return 0
      fi
    fi
    
    # 기존 프로젝트 삭제
    log_info "기존 프로젝트 '$project_name' 삭제 중..."
    ddev delete -O "$project_name" &>/dev/null
  fi
  
  # 프로젝트 설정
  log_info "프로젝트 '$project_name' 설정 중..."
  setup_project "$project_name" "$project_type"
  
  if [ $? -ne 0 ]; then
    log_error "프로젝트 설정 실패"
    return 1
  fi
  
  # DDEV 시작
  log_info "DDEV 프로젝트 시작 중..."
  ddev start "$project_name"
  
  if [ $? -ne 0 ]; then
    log_error "DDEV 프로젝트 시작 실패"
    return 1
  fi
  
  # 백업 복원
  log_info "백업 파일에서 데이터베이스 복원 중..."
  
  if ddev import-db --src="$backup_file" "$project_name"; then
    log_info "데이터베이스 복원 완료"
    
    # WordPress인 경우 URL 업데이트
    if [ "$project_type" == "wordpress" ]; then
      log_info "WordPress URL 업데이트 중..."
      cd "$project_dir" || return 1
      ddev exec wp search-replace --all-tables --skip-columns=guid "https://[^\.]*\.ddev\.site" "https://$project_name.ddev.site" || true
      cd "$current_dir" || return 1
    fi
    
    # 프로젝트 목록에 추가
    add_to_project_list "$project_name"
    
    # 성공 메시지
    log_info "복원이 완료되었습니다."
    log_info "프로젝트 URL: https://$project_name.ddev.site"
    
    return 0
  else
    log_error "데이터베이스 복원 실패"
    return 1
  fi
}

# 메인 스크립트 시작
BACKUP_FILE=""
PROJECT_NAME=""
PROJECT_TYPE="wordpress"
AUTO_YES="false"

# 명령줄 인수 파싱
while (( "$#" )); do
  case "$1" in
    -f|--file)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        BACKUP_FILE="$2"
        shift 2
      else
        log_error "오류: --file 인수 누락"
        show_usage
        exit 1
      fi
      ;;
    -n|--name)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        PROJECT_NAME="$2"
        shift 2
      else
        log_error "오류: --name 인수 누락"
        show_usage
        exit 1
      fi
      ;;
    -t|--type)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        PROJECT_TYPE="$2"
        shift 2
      else
        log_error "오류: --type 인수 누락"
        show_usage
        exit 1
      fi
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

# 인수 확인
if [ -z "$BACKUP_FILE" ] && [ -z "$PROJECT_NAME" ]; then
  # 백업 파일 목록 표시 모드
  list_backups
  exit 0
fi

# 백업 파일과 프로젝트 이름 필수
if [ -z "$BACKUP_FILE" ]; then
  log_error "백업 파일 경로(--file)를 지정해야 합니다."
  show_usage
  exit 1
fi

# 프로젝트 이름이 없는 경우 파일명에서 추출 시도
if [ -z "$PROJECT_NAME" ]; then
  if extract_project_name_from_file "$BACKUP_FILE" > /dev/null; then
    PROJECT_NAME="$(extract_project_name_from_file "$BACKUP_FILE")"
    log_info "파일명에서 프로젝트 이름 추출: $PROJECT_NAME"
  else
    log_error "프로젝트 이름(--name)을 지정해야 합니다."
    show_usage
    exit 1
  fi
fi

# 프로젝트 타입 검증
if [ "$PROJECT_TYPE" != "wordpress" ] && [ "$PROJECT_TYPE" != "laravel" ]; then
  log_error "프로젝트 타입은 'wordpress' 또는 'laravel'이어야 합니다."
  show_usage
  exit 1
fi

# 백업 복원 실행
restore_backup "$BACKUP_FILE" "$PROJECT_NAME" "$PROJECT_TYPE" "$AUTO_YES"
exit $? 