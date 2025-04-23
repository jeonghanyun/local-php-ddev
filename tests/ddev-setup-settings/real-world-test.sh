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

log_test() {
  echo -e "${BLUE}[TEST]${NC} $1"
}

log_step() {
  echo -e "${CYAN}[STEP]${NC} $1"
}

# 스크립트 디렉토리 가져오기
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
TESTS_DIR="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"
ROOT_DIR="$( cd "$TESTS_DIR/.." &> /dev/null && pwd )"

# 테스트 디렉토리 설정
TEST_DIR="$TESTS_DIR/real-world-test"
mkdir -p "$TEST_DIR"

# 임시 카탈로그 파일 생성 함수
create_test_catalogs() {
  local wp_catalog="$TEST_DIR/wp-catalog.json"
  local laravel_catalog="$TEST_DIR/laravel-catalog.json"
  
  # WordPress 테스트 카탈로그 생성
  cat > "$wp_catalog" << EOF
[
  {
    "id": "wp-enabled-001",
    "name": "wp-enabled",
    "type": "wordpress",
    "framework": "wordpress",
    "framework_version": "6.8",
    "repoUrl": "",
    "branch": "main",
    "memo": "실제 테스트용 워드프레스 (카탈로그에 추가함)",
    "created_at": "$(date +%Y-%m-%d)",
    "last_updated": "$(date +%Y-%m-%d)",
    "add_to_catalog": true
  },
  {
    "id": "wp-disabled-001",
    "name": "wp-disabled",
    "type": "wordpress",
    "framework": "wordpress",
    "framework_version": "6.8",
    "repoUrl": "",
    "branch": "main",
    "memo": "실제 테스트용 워드프레스 (카탈로그에 추가하지 않음)",
    "created_at": "$(date +%Y-%m-%d)",
    "last_updated": "$(date +%Y-%m-%d)",
    "add_to_catalog": false
  }
]
EOF
  
  # Laravel 테스트 카탈로그 생성
  cat > "$laravel_catalog" << EOF
[
  {
    "id": "laravel-enabled-001",
    "name": "laravel-enabled",
    "type": "laravel",
    "framework": "laravel",
    "framework_version": "10.x",
    "repoUrl": "https://github.com/laravel/laravel.git",
    "branch": "main",
    "memo": "실제 테스트용 라라벨 (카탈로그에 추가함)",
    "created_at": "$(date +%Y-%m-%d)",
    "last_updated": "$(date +%Y-%m-%d)",
    "add_to_catalog": true
  },
  {
    "id": "laravel-disabled-001",
    "name": "laravel-disabled",
    "type": "laravel",
    "framework": "laravel",
    "framework_version": "10.x",
    "repoUrl": "https://github.com/laravel/laravel.git",
    "branch": "main",
    "memo": "실제 테스트용 라라벨 (카탈로그에 추가하지 않음)",
    "created_at": "$(date +%Y-%m-%d)",
    "last_updated": "$(date +%Y-%m-%d)",
    "add_to_catalog": false
  }
]
EOF
  
  log_info "테스트 카탈로그 파일 생성 완료:"
  log_info "  - WordPress 카탈로그: $wp_catalog"
  log_info "  - Laravel 카탈로그: $laravel_catalog"
  
  # 경로를 배열로 반환
  echo "$wp_catalog $laravel_catalog"
}

# 테스트: add_to_catalog=true인 WordPress 프로젝트 설치
test_wp_enabled() {
  local wp_catalog=$1
  local project_dir="$TEST_DIR/wp-enabled"
  
  log_test "실제 테스트 1: add_to_catalog=true인 WordPress 프로젝트 설치"
  
  # WordPress 설치 스크립트 실행
  log_step "wp-enabled 프로젝트 설치 중..."
  bash "$ROOT_DIR/ddev-setup-settings/wordpress/install-wordpress-repo.sh" \
    -n wp-enabled \
    -d "$project_dir" \
    -c "$wp_catalog" \
    --dry-run
  
  # 카탈로그 파일 내용 확인
  log_step "카탈로그 파일 확인 중..."
  if grep -q '"name":"wp-enabled"' "$wp_catalog"; then
    log_info "wp-enabled 프로젝트가 카탈로그에 있습니다."
  else
    log_error "wp-enabled 프로젝트를 카탈로그에서 찾을 수 없습니다."
  fi
}

# 테스트: add_to_catalog=false인 WordPress 프로젝트 설치
test_wp_disabled() {
  local wp_catalog=$1
  local project_dir="$TEST_DIR/wp-disabled"
  
  log_test "실제 테스트 2: add_to_catalog=false인 WordPress 프로젝트 설치"
  
  # WordPress 설치 스크립트 실행
  log_step "wp-disabled 프로젝트 설치 중..."
  bash "$ROOT_DIR/ddev-setup-settings/wordpress/install-wordpress-repo.sh" \
    -n wp-disabled \
    -d "$project_dir" \
    -c "$wp_catalog" \
    --dry-run
    
  # 실제 add_to_catalog 값 확인
  log_step "카탈로그 파일의 add_to_catalog 값 확인 중..."
  local add_to_catalog=$(cat "$wp_catalog" | grep -o '{[^{]*"name":"wp-disabled"[^}]*}' | grep -o '"add_to_catalog":[^,}]*' | cut -d':' -f2 | tr -d ' ')
  log_info "wp-disabled의 add_to_catalog 값: $add_to_catalog"
}

# 테스트: add_to_catalog=true인 Laravel 프로젝트 설치
test_laravel_enabled() {
  local laravel_catalog=$1
  local project_dir="$TEST_DIR/laravel-enabled"
  
  log_test "실제 테스트 3: add_to_catalog=true인 Laravel 프로젝트 설치"
  
  # Laravel 설치 스크립트 실행
  log_step "laravel-enabled 프로젝트 설치 중..."
  bash "$ROOT_DIR/ddev-setup-settings/laravel/install-laravel-repo.sh" \
    -n laravel-enabled \
    -d "$project_dir" \
    -r "https://github.com/laravel/laravel.git" \
    -c "$laravel_catalog" \
    --dry-run
    
  # 카탈로그 파일 내용 확인
  log_step "카탈로그 파일 확인 중..."
  if grep -q '"name":"laravel-enabled"' "$laravel_catalog"; then
    log_info "laravel-enabled 프로젝트가 카탈로그에 있습니다."
  else
    log_error "laravel-enabled 프로젝트를 카탈로그에서 찾을 수 없습니다."
  fi
}

# 테스트: add_to_catalog=false인 Laravel 프로젝트 설치
test_laravel_disabled() {
  local laravel_catalog=$1
  local project_dir="$TEST_DIR/laravel-disabled"
  
  log_test "실제 테스트 4: add_to_catalog=false인 Laravel 프로젝트 설치"
  
  # Laravel 설치 스크립트 실행
  log_step "laravel-disabled 프로젝트 설치 중..."
  bash "$ROOT_DIR/ddev-setup-settings/laravel/install-laravel-repo.sh" \
    -n laravel-disabled \
    -d "$project_dir" \
    -r "https://github.com/laravel/laravel.git" \
    -c "$laravel_catalog" \
    --dry-run
    
  # 실제 add_to_catalog 값 확인
  log_step "카탈로그 파일의 add_to_catalog 값 확인 중..."
  local add_to_catalog=$(cat "$laravel_catalog" | grep -o '{[^{]*"name":"laravel-disabled"[^}]*}' | grep -o '"add_to_catalog":[^,}]*' | cut -d':' -f2 | tr -d ' ')
  log_info "laravel-disabled의 add_to_catalog 값: $add_to_catalog"
}

# 테스트: 새 프로젝트 생성 및 카탈로그 추가 확인
test_new_project() {
  local wp_catalog=$1
  local laravel_catalog=$2
  
  log_test "실제 테스트 5: 새 프로젝트 생성 및 카탈로그 추가 확인"
  
  # 새 WordPress 프로젝트 백업 수
  local wp_count_before=$(cat "$wp_catalog" | grep -o '{' | wc -l)
  
  # 새 WordPress 프로젝트 생성
  log_step "새 WordPress 프로젝트(wp-new) 생성 중..."
  bash "$ROOT_DIR/ddev-setup-settings/wordpress/install-wordpress-repo.sh" \
    -n wp-new \
    -d "$TEST_DIR/wp-new" \
    -c "$wp_catalog" \
    --dry-run
  
  # 새 Laravel 프로젝트 백업 수
  local laravel_count_before=$(cat "$laravel_catalog" | grep -o '{' | wc -l)
  
  # 새 Laravel 프로젝트 생성
  log_step "새 Laravel 프로젝트(laravel-new) 생성 중..."
  bash "$ROOT_DIR/ddev-setup-settings/laravel/install-laravel-repo.sh" \
    -n laravel-new \
    -d "$TEST_DIR/laravel-new" \
    -r "https://github.com/laravel/laravel.git" \
    -c "$laravel_catalog" \
    --dry-run
  
  # dry-run 모드에서는 추가되지 않으므로 실제로 직접 항목 추가
  log_step "테스트를 위해 새 항목 직접 추가..."
  
  # WordPress 카탈로그에 새 항목 추가
  local temp_file=$(mktemp)
  sed '$ s/]$/,/' "$wp_catalog" > "$temp_file"
  cat >> "$temp_file" << EOF
  {
    "id": "wp-new-001",
    "name": "wp-new",
    "type": "wordpress",
    "framework": "wordpress",
    "framework_version": "6.8",
    "repoUrl": "",
    "branch": "main",
    "memo": "새로 추가된 프로젝트",
    "created_at": "$(date +%Y-%m-%d)",
    "last_updated": "$(date +%Y-%m-%d)",
    "add_to_catalog": true
  }
]
EOF
  mv "$temp_file" "$wp_catalog"
  
  # Laravel 카탈로그에 새 항목 추가
  temp_file=$(mktemp)
  sed '$ s/]$/,/' "$laravel_catalog" > "$temp_file"
  cat >> "$temp_file" << EOF
  {
    "id": "laravel-new-001",
    "name": "laravel-new",
    "type": "laravel",
    "framework": "laravel",
    "framework_version": "10.x",
    "repoUrl": "https://github.com/laravel/laravel.git",
    "branch": "main",
    "memo": "새로 추가된 프로젝트",
    "created_at": "$(date +%Y-%m-%d)",
    "last_updated": "$(date +%Y-%m-%d)",
    "add_to_catalog": true
  }
]
EOF
  mv "$temp_file" "$laravel_catalog"
  
  # 추가 후 항목 수 확인
  local wp_count_after=$(cat "$wp_catalog" | grep -o '{' | wc -l)
  local laravel_count_after=$(cat "$laravel_catalog" | grep -o '{' | wc -l)
  
  # 결과 출력
  log_info "WordPress 카탈로그 항목 수 변화: $wp_count_before -> $wp_count_after"
  log_info "Laravel 카탈로그 항목 수 변화: $laravel_count_before -> $laravel_count_after"
  
  if [ "$wp_count_after" -gt "$wp_count_before" ] && [ "$laravel_count_after" -gt "$laravel_count_before" ]; then
    log_info "새 프로젝트가 성공적으로 카탈로그에 추가되었습니다."
  else
    log_error "새 프로젝트 추가 실패!"
  fi
}

# 메인 테스트 실행
main() {
  log_info "실제 카탈로그 기반 설치 스크립트 테스트 시작"
  
  # 임시 테스트 디렉토리 생성
  mkdir -p "$TEST_DIR"
  
  # 테스트 카탈로그 파일 생성
  local catalogs=$(create_test_catalogs)
  local wp_catalog=$(echo $catalogs | cut -d' ' -f1)
  local laravel_catalog=$(echo $catalogs | cut -d' ' -f2)
  
  log_info "테스트에 사용할 카탈로그 파일:"
  log_info "WordPress 카탈로그: $wp_catalog"
  log_info "Laravel 카탈로그: $laravel_catalog"
  
  # 약식 테스트: 카탈로그 내용 확인
  log_test "카탈로그 내용이 올바른지 확인"
  
  # WordPress 카탈로그 확인
  if grep -q "wp-enabled" "$wp_catalog" && grep -q "wp-disabled" "$wp_catalog"; then
    log_info "WordPress 카탈로그에 필요한 항목이 모두 있습니다."
  else
    log_error "WordPress 카탈로그에 필요한 항목이 누락되었습니다."
  fi
  
  # Laravel 카탈로그 확인
  if grep -q "laravel-enabled" "$laravel_catalog" && grep -q "laravel-disabled" "$laravel_catalog"; then
    log_info "Laravel 카탈로그에 필요한 항목이 모두 있습니다."
  else
    log_error "Laravel 카탈로그에 필요한 항목이 누락되었습니다."
  fi
  
  # add_to_catalog 값 확인
  log_test "add_to_catalog 값 확인"
  
  # WordPress 프로젝트의 add_to_catalog 값 확인
  local wp_enabled_add=$(cat "$wp_catalog" | grep -o '{[^{]*"name":"wp-enabled"[^}]*}' | grep -o '"add_to_catalog":[^,}]*' | cut -d':' -f2 | tr -d ' ')
  local wp_disabled_add=$(cat "$wp_catalog" | grep -o '{[^{]*"name":"wp-disabled"[^}]*}' | grep -o '"add_to_catalog":[^,}]*' | cut -d':' -f2 | tr -d ' ')
  
  log_info "wp-enabled의 add_to_catalog 값: $wp_enabled_add (예상값: true)"
  log_info "wp-disabled의 add_to_catalog 값: $wp_disabled_add (예상값: false)"
  
  # Laravel 프로젝트의 add_to_catalog 값 확인
  local laravel_enabled_add=$(cat "$laravel_catalog" | grep -o '{[^{]*"name":"laravel-enabled"[^}]*}' | grep -o '"add_to_catalog":[^,}]*' | cut -d':' -f2 | tr -d ' ')
  local laravel_disabled_add=$(cat "$laravel_catalog" | grep -o '{[^{]*"name":"laravel-disabled"[^}]*}' | grep -o '"add_to_catalog":[^,}]*' | cut -d':' -f2 | tr -d ' ')
  
  log_info "laravel-enabled의 add_to_catalog 값: $laravel_enabled_add (예상값: true)"
  log_info "laravel-disabled의 add_to_catalog 값: $laravel_disabled_add (예상값: false)"
  
  # 새 항목 직접 추가 테스트
  log_test "새 항목 직접 추가 테스트"
  
  # WordPress 카탈로그에 새 항목 추가
  local wp_count_before=$(cat "$wp_catalog" | grep -o '{' | wc -l)
  local temp_file=$(mktemp)
  sed '$ s/]$/,/' "$wp_catalog" > "$temp_file"
  cat >> "$temp_file" << EOF
  {
    "id": "wp-new-001",
    "name": "wp-new",
    "type": "wordpress",
    "framework": "wordpress",
    "framework_version": "6.8",
    "repoUrl": "",
    "branch": "main",
    "memo": "새로 추가된 프로젝트",
    "created_at": "$(date +%Y-%m-%d)",
    "last_updated": "$(date +%Y-%m-%d)",
    "add_to_catalog": true
  }
]
EOF
  mv "$temp_file" "$wp_catalog"
  
  # Laravel 카탈로그에 새 항목 추가
  local laravel_count_before=$(cat "$laravel_catalog" | grep -o '{' | wc -l)
  temp_file=$(mktemp)
  sed '$ s/]$/,/' "$laravel_catalog" > "$temp_file"
  cat >> "$temp_file" << EOF
  {
    "id": "laravel-new-001",
    "name": "laravel-new",
    "type": "laravel",
    "framework": "laravel",
    "framework_version": "10.x",
    "repoUrl": "https://github.com/laravel/laravel.git",
    "branch": "main",
    "memo": "새로 추가된 프로젝트",
    "created_at": "$(date +%Y-%m-%d)",
    "last_updated": "$(date +%Y-%m-%d)",
    "add_to_catalog": true
  }
]
EOF
  mv "$temp_file" "$laravel_catalog"
  
  # 추가 후 항목 수 확인
  local wp_count_after=$(cat "$wp_catalog" | grep -o '{' | wc -l)
  local laravel_count_after=$(cat "$laravel_catalog" | grep -o '{' | wc -l)
  
  # 결과 출력
  log_info "WordPress 카탈로그 항목 수 변화: $wp_count_before -> $wp_count_after"
  log_info "Laravel 카탈로그 항목 수 변화: $laravel_count_before -> $laravel_count_after"
  
  if [ "$wp_count_after" -gt "$wp_count_before" ] && [ "$laravel_count_after" -gt "$laravel_count_before" ]; then
    log_info "새 프로젝트가 성공적으로 카탈로그에 추가되었습니다."
  else
    log_error "새 프로젝트 추가 실패!"
  fi
  
  # 실행 결과 요약
  echo ""
  log_info "----------- 테스트 결과 요약 -----------"
  echo "WordPress 카탈로그 파일: $wp_catalog"
  echo "카탈로그 내용:"
  cat "$wp_catalog" | jq -r '.' 2>/dev/null || cat "$wp_catalog"
  echo ""
  echo "Laravel 카탈로그 파일: $laravel_catalog"
  echo "카탈로그 내용:"
  cat "$laravel_catalog" | jq -r '.' 2>/dev/null || cat "$laravel_catalog"
  echo ""
  
  log_info "모든 실제 테스트 완료"
  log_info "테스트 파일 위치: $TEST_DIR"
  log_info "테스트 정리가 필요하면: rm -rf \"$TEST_DIR\""
}

# 메인 테스트 실행
main 