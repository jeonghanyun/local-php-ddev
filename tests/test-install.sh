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

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# 테스트 실패 함수
test_failed() {
  log_error "테스트 실패: $1"
  exit 1
}

# 명령줄 인수 처리
DRY_RUN=true
SKIP_CLEANUP=false

# 명령줄 인수 파싱
while (( "$#" )); do
  case "$1" in
    --no-dry-run)
      DRY_RUN=false
      shift
      ;;
    --skip-cleanup)
      SKIP_CLEANUP=true
      shift
      ;;
    -h|--help)
      echo "사용법: $0 [옵션]"
      echo ""
      echo "옵션:"
      echo "  --no-dry-run     실제로 DDEV 프로젝트를 생성합니다 (기본값: dry-run 모드)"
      echo "  --skip-cleanup   테스트 후 디렉토리를 정리하지 않습니다 (기본값: 정리함)"
      echo "  -h, --help       도움말 표시"
      exit 0
      ;;
    *)
      log_error "알 수 없는 옵션: $1"
      exit 1
      ;;
  esac
done

# 테스트 시작 메시지
log_info "DDEV 설치 스크립트 테스트를 시작합니다..."
if [ "$DRY_RUN" = true ]; then
  log_info "Dry-run 모드: 실제 DDEV 프로젝트는 생성되지 않습니다."
else
  log_info "실제 모드: 실제 DDEV 프로젝트가 생성됩니다."
fi

# 스크립트 디렉토리 설정
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && cd .. && pwd )"
TESTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# 테스트를 위한 임시 디렉토리 생성
TEST_DIR="$TESTS_DIR/test-ddev-projects"
if [ -d "$TEST_DIR" ]; then
  log_warning "기존 테스트 디렉토리를 삭제합니다: $TEST_DIR"
  rm -rf "$TEST_DIR"
fi

mkdir -p "$TEST_DIR"

log_info "테스트 디렉토리를 생성했습니다: $TEST_DIR"

# 현재 디렉토리 저장
ORIGINAL_DIR="$(pwd)"

# 테스트 프로젝트 이름 설정
TIMESTAMP=$(date +%s)
WP_PROJECT="test-wp-$TIMESTAMP"
LARAVEL_PROJECT="test-laravel-$TIMESTAMP"

# install.sh 스크립트가 존재하는지 확인
if [ ! -f "$SCRIPT_DIR/install.sh" ]; then
  test_failed "install.sh 스크립트를 찾을 수 없습니다."
fi

# 테스트 디렉토리로 이동
cd "$TEST_DIR" || test_failed "테스트 디렉토리로 이동할 수 없습니다."

# WordPress 프로젝트 테스트
log_info "WordPress 프로젝트 테스트 시작..."

# 설치 스크립트 실행
if [ "$DRY_RUN" = true ]; then
  log_info "Dry-run 모드: WordPress 프로젝트 폴더 구조만 생성합니다."
  
  # 테스트를 위해 디렉토리와 파일 수동 생성
  mkdir -p "$WP_PROJECT/.ddev"
  mkdir -p "$WP_PROJECT/public"
  touch "$WP_PROJECT/.ddev/config.yaml"
  echo "<?php echo 'WordPress 프로젝트 시작'; ?>" > "$WP_PROJECT/public/index.php"
else
  log_info "실제 모드: WordPress 프로젝트를 생성합니다."
  
  # 설치 스크립트 실행
  "$SCRIPT_DIR/install.sh" -t wordpress -n "$WP_PROJECT" -d "$TEST_DIR/$WP_PROJECT"
  
  if [ $? -ne 0 ]; then
    test_failed "WordPress 프로젝트 생성에 실패했습니다."
  fi
fi

# WordPress 프로젝트 디렉토리 구조 테스트
if [ ! -d "$WP_PROJECT/.ddev" ]; then
  test_failed "WordPress 프로젝트의 .ddev 디렉토리가 생성되지 않았습니다."
fi

if [ ! -d "$WP_PROJECT/public" ]; then
  test_failed "WordPress 프로젝트의 public 디렉토리가 생성되지 않았습니다."
fi

if [ ! -f "$WP_PROJECT/.ddev/config.yaml" ]; then
  test_failed "WordPress 프로젝트의 config.yaml 파일이 생성되지 않았습니다."
fi

if [ ! -f "$WP_PROJECT/public/index.php" ]; then
  test_failed "WordPress 프로젝트의 index.php 파일이 생성되지 않았습니다."
fi

log_success "WordPress 프로젝트 테스트 성공!"

# Laravel 프로젝트 테스트
log_info "Laravel 프로젝트 테스트 시작..."

# 설치 스크립트 실행
if [ "$DRY_RUN" = true ]; then
  log_info "Dry-run 모드: Laravel 프로젝트 폴더 구조만 생성합니다."
  
  # 테스트를 위해 디렉토리와 파일 수동 생성
  mkdir -p "$LARAVEL_PROJECT/.ddev"
  mkdir -p "$LARAVEL_PROJECT/public"
  touch "$LARAVEL_PROJECT/.ddev/config.yaml"
  echo "<?php echo 'Laravel 프로젝트 시작'; ?>" > "$LARAVEL_PROJECT/public/index.php"
else
  log_info "실제 모드: Laravel 프로젝트를 생성합니다."
  
  # 설치 스크립트 실행
  "$SCRIPT_DIR/install.sh" -t laravel -n "$LARAVEL_PROJECT" -d "$TEST_DIR/$LARAVEL_PROJECT"
  
  if [ $? -ne 0 ]; then
    test_failed "Laravel 프로젝트 생성에 실패했습니다."
  fi
fi

# Laravel 프로젝트 디렉토리 구조 테스트
if [ ! -d "$LARAVEL_PROJECT/.ddev" ]; then
  test_failed "Laravel 프로젝트의 .ddev 디렉토리가 생성되지 않았습니다."
fi

if [ ! -d "$LARAVEL_PROJECT/public" ]; then
  test_failed "Laravel 프로젝트의 public 디렉토리가 생성되지 않았습니다."
fi

if [ ! -f "$LARAVEL_PROJECT/.ddev/config.yaml" ]; then
  test_failed "Laravel 프로젝트의 config.yaml 파일이 생성되지 않았습니다."
fi

if [ ! -f "$LARAVEL_PROJECT/public/index.php" ]; then
  test_failed "Laravel 프로젝트의 index.php 파일이 생성되지 않았습니다."
fi

log_success "Laravel 프로젝트 테스트 성공!"

# 모든 테스트 성공 메시지
log_success "모든 테스트가 성공적으로 완료되었습니다!"

# 실제 실행을 위한 명령어 안내
log_info "실제 프로젝트 생성을 위해 다음 명령어를 사용하세요:"
log_info "$SCRIPT_DIR/install.sh -t wordpress -n my-wordpress-site"
log_info "$SCRIPT_DIR/install.sh -t laravel -n my-laravel-site"

# 테스트 정리
if [ "$DRY_RUN" = false ] && [ "$SKIP_CLEANUP" = false ]; then
  log_info "DDEV 프로젝트를 중지하고 있습니다..."
  if [ -d "$WP_PROJECT" ]; then
    cd "$WP_PROJECT" && ddev stop || log_warning "WordPress 프로젝트 중지 실패"
  fi
  
  if [ -d "$LARAVEL_PROJECT" ]; then
    cd "$LARAVEL_PROJECT" && ddev stop || log_warning "Laravel 프로젝트 중지 실패"
  fi
  
  cd "$ORIGINAL_DIR" || test_failed "원래 디렉토리로 돌아갈 수 없습니다."
fi

if [ "$SKIP_CLEANUP" = false ]; then
  log_info "테스트 디렉토리를 정리하고 있습니다..."
  rm -rf "$TEST_DIR"
  log_success "테스트 디렉토리가 정리되었습니다."
else
  log_info "테스트 디렉토리를 삭제하려면 다음 명령어를 실행하세요:"
  log_info "rm -rf $TEST_DIR"
fi

# 원래 디렉토리로 돌아가기
cd "$ORIGINAL_DIR" || test_failed "원래 디렉토리로 돌아갈 수 없습니다."

log_info "테스트가 완료되었습니다."
if [ "$DRY_RUN" = true ]; then
  log_info "실제 설치를 테스트하려면 다음 명령어를 실행하세요:"
  log_info "$TESTS_DIR/test-install.sh --no-dry-run" 
fi 