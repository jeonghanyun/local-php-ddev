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

# 테스트 시작 메시지
log_info "DDEV 설치 스크립트 테스트를 시작합니다..."

# 테스트를 위한 임시 디렉토리 생성
TEST_DIR="test-ddev-projects"
if [ -d "$TEST_DIR" ]; then
  log_warning "기존 테스트 디렉토리를 삭제합니다: $TEST_DIR"
  rm -rf "$TEST_DIR"
fi
mkdir -p "$TEST_DIR"
SCRIPT_DIR="$(pwd)"

log_info "테스트 디렉토리를 생성했습니다: $TEST_DIR"

# WordPress 프로젝트 테스트
log_info "WordPress 프로젝트 테스트 시작..."
WP_TEST_NAME="test-wp-site"
WP_TEST_DIR="$TEST_DIR/$WP_TEST_NAME"
WP_TEST_CMD="$SCRIPT_DIR/install.sh -t wordpress -n $WP_TEST_NAME -d $WP_TEST_DIR --dry-run"

log_info "테스트 WordPress 프로젝트 생성 명령: $WP_TEST_CMD"
$WP_TEST_CMD

if [ $? -ne 0 ]; then
  log_error "WordPress 프로젝트 테스트 실패!"
  exit 1
fi

log_success "WordPress 프로젝트 테스트 성공!"

# Laravel 프로젝트 테스트
log_info "Laravel 프로젝트 테스트 시작..."
LARAVEL_TEST_NAME="test-laravel-site"
LARAVEL_TEST_DIR="$TEST_DIR/$LARAVEL_TEST_NAME"
LARAVEL_TEST_CMD="$SCRIPT_DIR/install.sh -t laravel -n $LARAVEL_TEST_NAME -d $LARAVEL_TEST_DIR --dry-run"

log_info "테스트 Laravel 프로젝트 생성 명령: $LARAVEL_TEST_CMD"
$LARAVEL_TEST_CMD

if [ $? -ne 0 ]; then
  log_error "Laravel 프로젝트 테스트 실패!"
  exit 1
fi

log_success "Laravel 프로젝트 테스트 성공!"

# 테스트 완료 메시지
log_success "모든 테스트가 성공적으로 완료되었습니다!"

# 실제 사용 안내
log_info "실제 프로젝트 생성을 위해 다음 명령어를 사용하세요:"
log_info "./install.sh -t wordpress -n my-wordpress-site"
log_info "./install.sh -t laravel -n my-laravel-site"

# 테스트 디렉토리 정리 안내
log_info "테스트 디렉토리를 삭제하려면 다음 명령어를 실행하세요:"
log_info "rm -rf test-ddev-projects" 