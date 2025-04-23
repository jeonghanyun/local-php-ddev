#!/bin/bash

# ANSI 색상 코드
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
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

log_test() {
  echo -e "${BLUE}[TEST]${NC} $1"
}

# 스크립트 디렉토리 가져오기
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
TESTS_DIR="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"
ROOT_DIR="$( cd "$TESTS_DIR/.." &> /dev/null && pwd )"

# 테스트 디렉토리 설정
TEST_DIR="$TESTS_DIR/test-projects"
mkdir -p "$TEST_DIR"

# 임시 카탈로그 파일 생성 함수
create_temp_catalogs() {
  local wp_temp="$TEST_DIR/wp-catalog-test.json"
  local laravel_temp="$TEST_DIR/laravel-catalog-test.json"
  
  # WordPress 임시 카탈로그 생성
  cat > "$wp_temp" << EOF
[
  {
    "id": "wp-test-enabled-001",
    "name": "wp-test-enabled",
    "type": "wordpress",
    "framework": "wordpress",
    "framework_version": "6.8",
    "repoUrl": "",
    "branch": "main",
    "memo": "테스트용 워드프레스 (카탈로그에 추가함)",
    "created_at": "2024-04-26",
    "last_updated": "2024-04-26",
    "add_to_catalog": true
  },
  {
    "id": "wp-test-disabled-001",
    "name": "wp-test-disabled",
    "type": "wordpress",
    "framework": "wordpress",
    "framework_version": "6.8",
    "repoUrl": "",
    "branch": "main",
    "memo": "테스트용 워드프레스 (카탈로그에 추가하지 않음)",
    "created_at": "2024-04-26",
    "last_updated": "2024-04-26",
    "add_to_catalog": false
  }
]
EOF
  
  # Laravel 임시 카탈로그 생성
  cat > "$laravel_temp" << EOF
[
  {
    "id": "laravel-test-enabled-001",
    "name": "laravel-test-enabled",
    "type": "laravel",
    "framework": "laravel",
    "framework_version": "10.x",
    "repoUrl": "",
    "branch": "main",
    "memo": "테스트용 라라벨 (카탈로그에 추가함)",
    "created_at": "2024-04-26",
    "last_updated": "2024-04-26",
    "add_to_catalog": true
  },
  {
    "id": "laravel-test-disabled-001",
    "name": "laravel-test-disabled",
    "type": "laravel",
    "framework": "laravel",
    "framework_version": "10.x",
    "repoUrl": "",
    "branch": "main",
    "memo": "테스트용 라라벨 (카탈로그에 추가하지 않음)",
    "created_at": "2024-04-26",
    "last_updated": "2024-04-26",
    "add_to_catalog": false
  }
]
EOF
  
  log_info "임시 카탈로그 파일 생성 완료:"
  log_info "  - WordPress 카탈로그: $wp_temp"
  log_info "  - Laravel 카탈로그: $laravel_temp"
}

# 테스트 케이스 1: add_to_catalog=true인 WordPress 프로젝트 설치
test_wp_enabled() {
  log_test "케이스 1: add_to_catalog=true인 WordPress 프로젝트 설치 테스트"
  
  # 임시 카탈로그 파일 경로
  local catalog="$TEST_DIR/wp-catalog-test.json"
  
  # 테스트 전 카탈로그 파일 백업
  cp "$catalog" "$catalog.before"
  
  # WordPress 설치 스크립트 실행 (dry-run 모드)
  log_info "WordPress 설치 스크립트 실행 중 (wp-test-enabled)..."
  bash "$SCRIPT_DIR/wordpress/install-wordpress-repo.sh" \
    -n wp-test-enabled \
    -d "$TEST_DIR/wp-test-enabled" \
    -c "$catalog" \
    --dry-run
  
  # 카탈로그 파일 변경 확인
  if diff -q "$catalog" "$catalog.before" &>/dev/null; then
    log_warning "카탈로그 파일이 변경되지 않았습니다 (dry-run 모드에서는 정상)."
  else
    log_error "dry-run 모드에서 카탈로그 파일이 변경되었습니다 (오류)."
  fi
  
  # 원래 파일로 복구
  cp "$catalog.before" "$catalog"
  
  log_info "테스트 완료 (케이스 1)"
}

# 테스트 케이스 2: add_to_catalog=false인 WordPress 프로젝트 설치
test_wp_disabled() {
  log_test "케이스 2: add_to_catalog=false인 WordPress 프로젝트 설치 테스트"
  
  # 임시 카탈로그 파일 경로
  local catalog="$TEST_DIR/wp-catalog-test.json"
  
  # 테스트 전 카탈로그 파일 백업
  cp "$catalog" "$catalog.before"
  
  # WordPress 설치 스크립트 실행 (dry-run 모드)
  log_info "WordPress 설치 스크립트 실행 중 (wp-test-disabled)..."
  bash "$SCRIPT_DIR/wordpress/install-wordpress-repo.sh" \
    -n wp-test-disabled \
    -d "$TEST_DIR/wp-test-disabled" \
    -c "$catalog" \
    --dry-run
  
  # 카탈로그 파일 변경 확인
  if diff -q "$catalog" "$catalog.before" &>/dev/null; then
    log_warning "카탈로그 파일이 변경되지 않았습니다 (dry-run 모드에서는 정상)."
  else
    log_error "dry-run 모드에서 카탈로그 파일이 변경되었습니다 (오류)."
  fi
  
  # 원래 파일로 복구
  cp "$catalog.before" "$catalog"
  
  log_info "테스트 완료 (케이스 2)"
}

# 테스트 케이스 3: add_to_catalog=true인 Laravel 프로젝트 설치
test_laravel_enabled() {
  log_test "케이스 3: add_to_catalog=true인 Laravel 프로젝트 설치 테스트"
  
  # 임시 카탈로그 파일 경로
  local catalog="$TEST_DIR/laravel-catalog-test.json"
  
  # 테스트 전 카탈로그 파일 백업
  cp "$catalog" "$catalog.before"
  
  # Laravel 설치 스크립트 실행 (dry-run 모드)
  log_info "Laravel 설치 스크립트 실행 중 (laravel-test-enabled)..."
  bash "$SCRIPT_DIR/laravel/install-laravel-repo.sh" \
    -n laravel-test-enabled \
    -d "$TEST_DIR/laravel-test-enabled" \
    -r "https://github.com/laravel/laravel.git" \
    -c "$catalog" \
    --dry-run
  
  # 카탈로그 파일 변경 확인
  if diff -q "$catalog" "$catalog.before" &>/dev/null; then
    log_warning "카탈로그 파일이 변경되지 않았습니다 (dry-run 모드에서는 정상)."
  else
    log_error "dry-run 모드에서 카탈로그 파일이 변경되었습니다 (오류)."
  fi
  
  # 원래 파일로 복구
  cp "$catalog.before" "$catalog"
  
  log_info "테스트 완료 (케이스 3)"
}

# 테스트 케이스 4: add_to_catalog=false인 Laravel 프로젝트 설치
test_laravel_disabled() {
  log_test "케이스 4: add_to_catalog=false인 Laravel 프로젝트 설치 테스트"
  
  # 임시 카탈로그 파일 경로
  local catalog="$TEST_DIR/laravel-catalog-test.json"
  
  # 테스트 전 카탈로그 파일 백업
  cp "$catalog" "$catalog.before"
  
  # Laravel 설치 스크립트 실행 (dry-run 모드)
  log_info "Laravel 설치 스크립트 실행 중 (laravel-test-disabled)..."
  bash "$SCRIPT_DIR/laravel/install-laravel-repo.sh" \
    -n laravel-test-disabled \
    -d "$TEST_DIR/laravel-test-disabled" \
    -r "https://github.com/laravel/laravel.git" \
    -c "$catalog" \
    --dry-run
  
  # 카탈로그 파일 변경 확인
  if diff -q "$catalog" "$catalog.before" &>/dev/null; then
    log_warning "카탈로그 파일이 변경되지 않았습니다 (dry-run 모드에서는 정상)."
  else
    log_error "dry-run 모드에서 카탈로그 파일이 변경되었습니다 (오류)."
  fi
  
  # 원래 파일로 복구
  cp "$catalog.before" "$catalog"
  
  log_info "테스트 완료 (케이스 4)"
}

# 테스트 케이스 5: 카탈로그에 없는 새 WordPress 프로젝트 설치
test_wp_new() {
  log_test "케이스 5: 카탈로그에 없는 새 WordPress 프로젝트 설치 테스트"
  
  # 임시 카탈로그 파일 경로
  local catalog="$TEST_DIR/wp-catalog-test.json"
  
  # 테스트 전 카탈로그 파일 백업
  cp "$catalog" "$catalog.before"
  
  # WordPress 설치 스크립트 실행 (dry-run 모드)
  log_info "WordPress 설치 스크립트 실행 중 (wp-test-new)..."
  bash "$SCRIPT_DIR/wordpress/install-wordpress-repo.sh" \
    -n wp-test-new \
    -d "$TEST_DIR/wp-test-new" \
    -c "$catalog" \
    --dry-run
  
  # 카탈로그 파일 변경 확인
  if diff -q "$catalog" "$catalog.before" &>/dev/null; then
    log_warning "카탈로그 파일이 변경되지 않았습니다 (dry-run 모드에서는 정상)."
  else
    log_error "dry-run 모드에서 카탈로그 파일이 변경되었습니다 (오류)."
  fi
  
  # 원래 파일로 복구
  cp "$catalog.before" "$catalog"
  
  log_info "테스트 완료 (케이스 5)"
}

# 테스트 케이스 6: 카탈로그에 없는 새 Laravel 프로젝트 설치
test_laravel_new() {
  log_test "케이스 6: 카탈로그에 없는 새 Laravel 프로젝트 설치 테스트"
  
  # 임시 카탈로그 파일 경로
  local catalog="$TEST_DIR/laravel-catalog-test.json"
  
  # 테스트 전 카탈로그 파일 백업
  cp "$catalog" "$catalog.before"
  
  # Laravel 설치 스크립트 실행 (dry-run 모드)
  log_info "Laravel 설치 스크립트 실행 중 (laravel-test-new)..."
  bash "$SCRIPT_DIR/laravel/install-laravel-repo.sh" \
    -n laravel-test-new \
    -d "$TEST_DIR/laravel-test-new" \
    -r "https://github.com/laravel/laravel.git" \
    -c "$catalog" \
    --dry-run
  
  # 카탈로그 파일 변경 확인
  if diff -q "$catalog" "$catalog.before" &>/dev/null; then
    log_warning "카탈로그 파일이 변경되지 않았습니다 (dry-run 모드에서는 정상)."
  else
    log_error "dry-run 모드에서 카탈로그 파일이 변경되었습니다 (오류)."
  fi
  
  # 원래 파일로 복구
  cp "$catalog.before" "$catalog"
  
  log_info "테스트 완료 (케이스 6)"
}

# 메인 테스트 실행
main() {
  log_info "카탈로그 기반 설치 스크립트 테스트 시작"
  
  # 임시 테스트 디렉토리 생성
  mkdir -p "$TEST_DIR"
  
  # 임시 카탈로그 파일 생성
  create_temp_catalogs
  
  # 테스트 케이스 실행
  test_wp_enabled
  test_wp_disabled
  test_laravel_enabled
  test_laravel_disabled
  test_wp_new
  test_laravel_new
  
  log_info "모든 테스트 완료"
  log_info "테스트 파일 위치: $TEST_DIR"
  log_info "테스트 정리가 필요하면: rm -rf \"$TEST_DIR\""
}

# 메인 테스트 실행
main 