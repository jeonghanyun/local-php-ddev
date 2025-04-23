#!/bin/bash

# 현재 스크립트 디렉토리 가져오기
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# 색상 정의
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
PURPLE="\033[0;35m"
NC="\033[0m" # 색상 리셋

# 로그 함수
log_section() {
  echo -e "${PURPLE}▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓${NC}"
  echo -e "${PURPLE}▓▓ $1${NC}"
  echo -e "${PURPLE}▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓${NC}"
}

log_info() {
  echo -e "${BLUE}[정보]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[경고]${NC} $1"
}

log_error() {
  echo -e "${RED}[오류]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[성공]${NC} $1"
}

# 테스트 디렉토리 설정
TEST_DIR="/tmp/ddev-setup-test-$(date +%s)"
mkdir -p $TEST_DIR

log_info "테스트 디렉토리 생성: $TEST_DIR"

# 테스트 카탈로그 생성
mkdir -p $TEST_DIR/projects-env

# WordPress 카탈로그 생성
cat > $TEST_DIR/projects-env/wp-catalog.json << EOF
[
  {
    "name": "wp-test-1",
    "description": "WordPress 테스트 프로젝트 1",
    "version": "latest",
    "type": "wordpress",
    "add_to_catalog": true
  },
  {
    "name": "wp-test-2",
    "description": "WordPress 테스트 프로젝트 2",
    "version": "latest",
    "type": "wordpress",
    "add_to_catalog": false
  }
]
EOF

log_info "WordPress 카탈로그 생성 완료: $TEST_DIR/projects-env/wp-catalog.json"

# Laravel 카탈로그 생성
cat > $TEST_DIR/projects-env/laravel-catalog.json << EOF
[
  {
    "name": "laravel-test-1",
    "description": "Laravel 테스트 프로젝트 1",
    "version": "latest",
    "type": "laravel",
    "add_to_catalog": true,
    "repo": "https://github.com/laravel/laravel.git"
  },
  {
    "name": "laravel-test-2",
    "description": "Laravel 테스트 프로젝트 2",
    "version": "latest",
    "type": "laravel",
    "add_to_catalog": false,
    "repo": "https://github.com/laravel/laravel.git"
  }
]
EOF

log_info "Laravel 카탈로그 생성 완료: $TEST_DIR/projects-env/laravel-catalog.json"

# 카탈로그 내용 확인
log_debug "WordPress 카탈로그의 add_to_catalog 값 확인:"
grep "add_to_catalog" $TEST_DIR/projects-env/wp-catalog.json

log_debug "Laravel 카탈로그의 add_to_catalog 값 확인:"
grep "add_to_catalog" $TEST_DIR/projects-env/laravel-catalog.json

# 테스트 시작
cd $TEST_DIR
log_info "테스트를 시작합니다..."

# 테스트 1: WordPress 프로젝트 (add_to_catalog=true)
log_info "테스트 1: WordPress 프로젝트 (add_to_catalog=true)"
bash "../ddev-setup-settings/wordpress/install-wordpress-from-catalog.sh" \
  --name wp-test-1 \
  --directory "$TEST_DIR/wp-test-1" \
  --catalog "$TEST_DIR/projects-env/wp-catalog.json" \
  --dry-run

# 테스트 2: WordPress 프로젝트 (add_to_catalog=false)
log_info "테스트 2: WordPress 프로젝트 (add_to_catalog=false)"
bash "../ddev-setup-settings/wordpress/install-wordpress-from-catalog.sh" \
  --name wp-test-2 \
  --directory "$TEST_DIR/wp-test-2" \
  --catalog "$TEST_DIR/projects-env/wp-catalog.json" \
  --dry-run

# 테스트 3: 카탈로그에 없는 새 WordPress 프로젝트
log_info "테스트 3: 카탈로그에 없는 새 WordPress 프로젝트"
bash "../ddev-setup-settings/wordpress/install-wordpress-from-catalog.sh" \
  --name wp-test-new \
  --directory "$TEST_DIR/wp-test-new" \
  --catalog "$TEST_DIR/projects-env/wp-catalog.json" \
  --dry-run

# 테스트 4: Laravel 프로젝트 (add_to_catalog=true)
log_info "테스트 4: Laravel 프로젝트 (add_to_catalog=true)"
bash "../ddev-setup-settings/laravel/install-laravel-from-catalog.sh" \
  --name laravel-test-1 \
  --directory "$TEST_DIR/laravel-test-1" \
  --catalog "$TEST_DIR/projects-env/laravel-catalog.json" \
  --dry-run

# 테스트 5: WordPress 레포지토리 설치 (--no-install 옵션 사용)
log_info "테스트 5: WordPress 레포지토리 설치 (--no-install 옵션 사용)"
bash "../ddev-setup-settings/wordpress/install-wordpress-repo.sh" \
  --name wp-repo-no-install \
  --directory "$TEST_DIR/wp-repo-no-install" \
  --dry-run \
  --no-install

# 테스트 6: Laravel 레포지토리 설치 (--no-install 옵션 사용)
log_info "테스트 6: Laravel 레포지토리 설치 (--no-install 옵션 사용)"
bash "../ddev-setup-settings/laravel/install-laravel-repo.sh" \
  --name laravel-repo-no-install \
  --directory "$TEST_DIR/laravel-repo-no-install" \
  --repo "https://github.com/laravel/laravel.git" \
  --dry-run \
  --no-install

# 테스트 7: 일반 설치 테스트
log_info "테스트 7: WordPress 레포지토리 일반 설치"
bash "../ddev-setup-settings/wordpress/install-wordpress-repo.sh" \
  --name wp-repo-normal \
  --directory "$TEST_DIR/wp-repo-normal" \
  --dry-run

log_info "모든 테스트가 완료되었습니다."
log_info "테스트 디렉토리: $TEST_DIR"
log_info "테스트 후 정리: rm -rf $TEST_DIR"

# WordPress 간단 테스트
test_wordpress_simple() {
  log_section "WordPress 간단 테스트"
  local TEST_DIR="${ROOT_DIR}/test-wp-simple"
  local CATALOG_FILE="${TEST_DIR}/wp-catalog.json"

  # 테스트 디렉토리 생성
  mkdir -p "$TEST_DIR"
  
  # 테스트 카탈로그 생성
  cat > "$CATALOG_FILE" << EOL
[
  {
    "id": "wp-test-simple-001",
    "name": "wp-test-simple",
    "description": "간단한 WordPress 테스트 프로젝트",
    "version": "latest",
    "type": "wordpress",
    "add_to_catalog": true
  }
]
EOL

  log_info "테스트 카탈로그 생성 완료: $CATALOG_FILE"
  cat "$CATALOG_FILE"

  # WordPress 설치 스크립트 실행 (--no-install 옵션 추가)
  log_info "WordPress 설치 스크립트를 실행합니다 (--no-install 옵션)..."
  bash "${SCRIPT_DIR}/wordpress/install-wordpress.sh" \
    --name "wp-test-simple" \
    --directory "${TEST_DIR}/wp-test-simple" \
    --catalog "${CATALOG_FILE}" \
    --no-install

  # 결과 확인
  if [ -f "${TEST_DIR}/wp-test-simple/.ddev/config.yaml" ]; then
    log_error "DDEV 구성 파일이 존재합니다. --no-install 옵션이 제대로 작동하지 않았습니다."
    return 1
  else
    log_success "DDEV 구성 파일이 없습니다. --no-install 옵션이 제대로 작동했습니다."
  fi

  # 레지스트리 확인
  if [ -f "${ROOT_DIR}/ddev-projects/ddev-project-registry.json" ]; then
    log_info "레지스트리 파일이 존재합니다:"
    cat "${ROOT_DIR}/ddev-projects/ddev-project-registry.json"
    
    # WordPress 프로젝트가 레지스트리에 있는지 확인
    local entry_exists=$(jq '.[] | select(.name == "wp-test-simple") | .name' "${ROOT_DIR}/ddev-projects/ddev-project-registry.json")
    if [ -n "$entry_exists" ]; then
      log_success "WordPress 프로젝트가 레지스트리에 추가되었습니다: $entry_exists"
      
      # should_install 값이 false인지 확인
      local should_install=$(jq '.[] | select(.name == "wp-test-simple") | .should_install' "${ROOT_DIR}/ddev-projects/ddev-project-registry.json")
      if [ "$should_install" = "false" ]; then
        log_success "should_install 값이 올바르게 false로 설정되었습니다."
      else
        log_error "should_install 값이 false가 아닙니다: $should_install"
        return 1
      fi
    else
      log_error "WordPress 프로젝트가 레지스트리에 추가되지 않았습니다."
      return 1
    fi
  else
    log_error "레지스트리 파일이 존재하지 않습니다."
    return 1
  fi

  # 테스트 디렉토리 정리
  log_info "테스트 디렉토리 정리 중..."
  rm -rf "$TEST_DIR"
  log_success "테스트 디렉토리 정리 완료"
}

# Laravel 간단 테스트
test_laravel_simple() {
  log_section "Laravel 간단 테스트"
  local TEST_DIR="${ROOT_DIR}/test-laravel-simple"
  local CATALOG_FILE="${TEST_DIR}/laravel-catalog.json"

  # 테스트 디렉토리 생성
  mkdir -p "$TEST_DIR"
  
  # 테스트 카탈로그 생성
  cat > "$CATALOG_FILE" << EOL
[
  {
    "id": "laravel-test-simple-001",
    "name": "laravel-test-simple",
    "description": "간단한 Laravel 테스트 프로젝트",
    "version": "latest",
    "type": "laravel",
    "add_to_catalog": true
  }
]
EOL

  log_info "테스트 카탈로그 생성 완료: $CATALOG_FILE"
  cat "$CATALOG_FILE"

  # Laravel 설치 스크립트 실행 (--no-install 옵션 추가)
  log_info "Laravel 설치 스크립트를 실행합니다 (--no-install 옵션)..."
  bash "${SCRIPT_DIR}/laravel/install-laravel.sh" \
    --name "laravel-test-simple" \
    --directory "${TEST_DIR}/laravel-test-simple" \
    --catalog "${CATALOG_FILE}" \
    --no-install

  # 결과 확인
  if [ -f "${TEST_DIR}/laravel-test-simple/.ddev/config.yaml" ]; then
    log_error "DDEV 구성 파일이 존재합니다. --no-install 옵션이 제대로 작동하지 않았습니다."
    return 1
  else
    log_success "DDEV 구성 파일이 없습니다. --no-install 옵션이 제대로 작동했습니다."
  fi

  # 레지스트리 확인
  if [ -f "${ROOT_DIR}/ddev-projects/ddev-project-registry.json" ]; then
    log_info "레지스트리 파일이 존재합니다:"
    cat "${ROOT_DIR}/ddev-projects/ddev-project-registry.json"
    
    # Laravel 프로젝트가 레지스트리에 있는지 확인
    local entry_exists=$(jq '.[] | select(.name == "laravel-test-simple") | .name' "${ROOT_DIR}/ddev-projects/ddev-project-registry.json")
    if [ -n "$entry_exists" ]; then
      log_success "Laravel 프로젝트가 레지스트리에 추가되었습니다: $entry_exists"
      
      # should_install 값이 false인지 확인
      local should_install=$(jq '.[] | select(.name == "laravel-test-simple") | .should_install' "${ROOT_DIR}/ddev-projects/ddev-project-registry.json")
      if [ "$should_install" = "false" ]; then
        log_success "should_install 값이 올바르게 false로 설정되었습니다."
      else
        log_error "should_install 값이 false가 아닙니다: $should_install"
        return 1
      fi
    else
      log_error "Laravel 프로젝트가 레지스트리에 추가되지 않았습니다."
      return 1
    fi
  else
    log_error "레지스트리 파일이 존재하지 않습니다."
    return 1
  fi

  # 테스트 디렉토리 정리
  log_info "테스트 디렉토리 정리 중..."
  rm -rf "$TEST_DIR"
  log_success "테스트 디렉토리 정리 완료"
}

# 메인 함수
main() {
  log_section "간단 테스트 시작"
  
  # WordPress 간단 테스트 실행
  test_wordpress_simple
  
  # Laravel 간단 테스트 실행
  test_laravel_simple
  
  log_section "간단 테스트 완료"
}

# 스크립트 실행
main 