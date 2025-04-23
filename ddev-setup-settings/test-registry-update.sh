#!/bin/bash

# ANSI 색상 코드
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
PURPLE="\033[0;35m"
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

log_debug() {
  echo -e "${BLUE}[DEBUG]${NC} $1"
}

log_section() {
  echo -e "\n${PURPLE}=== $1 ===${NC}"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# 테스트 결과 카운터
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# 테스트 결과 기록 함수
test_result() {
  local test_name=$1
  local result=$2
  local message=$3
  
  TESTS_TOTAL=$((TESTS_TOTAL + 1))
  
  if [ "$result" == "pass" ]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    log_info "✅ 테스트 통과: $test_name - $message"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    log_error "❌ 테스트 실패: $test_name - $message"
  fi
}

# 단순 JSON 필드 확인 함수 (그냥 grep을 사용하는 방식)
check_json_field() {
  local file=$1
  local field=$2
  local expected_value=$3
  local project_name=$4
  
  # 프로젝트 이름이 지정된 경우 해당 프로젝트만 검색
  if [ -n "$project_name" ]; then
    # 프로젝트 이름이 정확히 일치하는 행 찾기
    if ! grep -q "\"name\":\"$project_name\"" "$file"; then
      log_debug "프로젝트 이름 '$project_name'을 찾을 수 없습니다."
      return 1
    fi
    
    # 프로젝트 이름 주변의 JSON 블록 추출 (프로젝트 이름부터 다음 닫는 괄호까지)
    local project_json=$(sed -n "/\"name\":\"$project_name\"/,/  }/p" "$file")
    
    # 문자열 값 확인
    if echo "$expected_value" | grep -q "^[a-zA-Z]"; then
      # expected_value가 문자열 (알파벳으로 시작)인 경우 따옴표 추가
      if echo "$project_json" | grep -q "\"$field\":\"$expected_value\""; then
        return 0
      fi
    # 불리언 또는 숫자 값 확인
    elif echo "$project_json" | grep -q "\"$field\":$expected_value"; then
      return 0
    fi
    
    # 필드 값이 일치하지 않음
    local found_value=$(echo "$project_json" | grep -o "\"$field\":[^,}]*" | head -n 1 | sed 's/.*://;s/^[ ]*//;s/[ ]*$//')
    log_debug "필드 '$field'에 대해 예상값: '$expected_value', 실제값: '$found_value'"
    return 1
  else
    # 모든 항목 중 첫 번째 일치하는 항목 확인
    if grep -q "\"$field\":\"$expected_value\"" "$file" || grep -q "\"$field\":$expected_value" "$file"; then
      return 0
    else
      return 1
    fi
  fi
}

# 스크립트 디렉토리 가져오기
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ROOT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

# 테스트 시작 시간 기록
START_TIME=$(date +%s)

# 테스트 디렉토리 및 레지스트리 파일 설정
TEST_DIR="${ROOT_DIR}/registry-test"
REGISTRY_FILE="${TEST_DIR}/ddev-project-registry.json"

# 테스트 디렉토리 생성
mkdir -p "$TEST_DIR"

# 초기 레지스트리 파일 생성 (기존 워드프레스 프로젝트 정보 포함)
cat > "$REGISTRY_FILE" << EOF
[
  {
    "id": "existing-wp-001",
    "name": "existing-wp",
    "type": "wordpress",
    "framework": "wordpress",
    "framework_version": "6.8",
    "repoUrl": "",
    "branch": "main",
    "local_url": "https://existing-wp.ddev.site",
    "directory": "/path/to/existing-wp",
    "db_name": "db",
    "db_user": "db",
    "php_version": "8.2",
    "webserver_type": "nginx-fpm",
    "should_install": true,
    "memo": "기존 WordPress 사이트",
    "created_at": "2024-04-26",
    "last_updated": "2024-04-26",
    "last_used": "2024-04-26"
  }
]
EOF

log_info "테스트 레지스트리 파일을 생성했습니다: $REGISTRY_FILE"

# 테스트 디렉토리 설정
TEST_DIR="$ROOT_DIR/registry-test"
rm -rf "$TEST_DIR" # 기존 테스트 디렉토리 정리
mkdir -p "$TEST_DIR"

# 임시 레지스트리 파일 생성
REGISTRY_FILE="$TEST_DIR/ddev-project-registry.json"

# 초기 레지스트리 파일 검증
if [ -f "$REGISTRY_FILE" ]; then
  test_result "레지스트리_파일_생성" "pass" "레지스트리 파일이 성공적으로 생성되었습니다."
else
  test_result "레지스트리_파일_생성" "fail" "레지스트리 파일 생성에 실패했습니다."
fi

# 초기 레지스트리에 항목 수 확인
initial_count=$(grep -o '"name"' "$REGISTRY_FILE" | wc -l | tr -d ' ')
if [ "$initial_count" -eq 1 ]; then
  test_result "초기_레지스트리_항목_수" "pass" "초기 레지스트리에 1개의 항목이 있습니다."
else
  test_result "초기_레지스트리_항목_수" "fail" "초기 레지스트리에 예상과 다른 항목 수가 있습니다: $initial_count"
fi

# 초기 레지스트리 필드 값 검증
if check_json_field "$REGISTRY_FILE" "should_install" "true" "existing-wp"; then
  test_result "초기_레지스트리_필드_값" "pass" "초기 레지스트리의 should_install 필드 값이 올바릅니다."
else
  test_result "초기_레지스트리_필드_값" "fail" "초기 레지스트리의 should_install 필드 값이 잘못되었거나 찾을 수 없습니다."
fi

# WordPress 레지스트리 업데이트 테스트
test_wordpress_registry_update() {
  log_section "WordPress 레지스트리 업데이트 테스트"
  
  local TEST_DIR="${ROOT_DIR}/test-registry-update"
  local REGISTRY_FILE="${TEST_DIR}/ddev-project-registry.json"
  local WP_PROJECT_NAME="wp-test-registry"
  
  log_info "WordPress 레지스트리 업데이트 테스트를 시작합니다..."
  log_info "테스트 디렉토리: ${TEST_DIR}"
  log_info "레지스트리 파일: ${REGISTRY_FILE}"
  
  # 설치 스크립트 실행
  log_info "WordPress 설치 스크립트 실행 중 (--registry-only 옵션)..."
  "${SCRIPT_DIR}/wordpress/install-wordpress-repo.sh" \
    --name "${WP_PROJECT_NAME}" \
    --registry-only \
    --registry-file "${REGISTRY_FILE}"
  
  # 레지스트리 파일 확인
  if [ -f "${REGISTRY_FILE}" ]; then
    log_success "레지스트리 파일이 존재합니다."
    
    # 항목 개수 확인
    local item_count=$(jq '. | length' "${REGISTRY_FILE}")
    if [ "${item_count}" -eq 2 ]; then
      log_success "레지스트리 파일에 정확히 2개의 항목이 있습니다."
    else
      log_error "레지스트리 파일에 2개의 항목이 없습니다. 실제 항목 수: ${item_count}"
      cat "${REGISTRY_FILE}"
      return 1
    fi
    
    # 새 프로젝트 확인
    local new_project=$(jq '.[] | select(.name == "'"${WP_PROJECT_NAME}"'") | .name' "${REGISTRY_FILE}")
    if [ -n "${new_project}" ]; then
      log_success "새 WordPress 프로젝트가 레지스트리에 추가되었습니다: ${new_project}"
    else
      log_error "새 WordPress 프로젝트가 레지스트리에 추가되지 않았습니다."
      cat "${REGISTRY_FILE}"
      return 1
    fi
  else
    log_error "레지스트리 파일이 존재하지 않습니다."
    return 1
  fi
}

# Laravel 레지스트리 업데이트 테스트
test_laravel_registry_update() {
  log_section "Laravel 레지스트리 업데이트 테스트"
  
  local TEST_DIR="${ROOT_DIR}/test-registry-update"
  local REGISTRY_FILE="${TEST_DIR}/ddev-project-registry.json"
  local LARAVEL_PROJECT_NAME="laravel-test-registry"
  
  log_info "Laravel 레지스트리 업데이트 테스트를 시작합니다..."
  log_info "테스트 디렉토리: ${TEST_DIR}"
  log_info "레지스트리 파일: ${REGISTRY_FILE}"
  
  # 설치 스크립트 실행
  log_info "Laravel 설치 스크립트 실행 중 (--registry-only 옵션)..."
  "${SCRIPT_DIR}/laravel/install-laravel-repo.sh" \
    --name "${LARAVEL_PROJECT_NAME}" \
    --registry-only \
    --registry-file "${REGISTRY_FILE}" \
    --no-install
  
  # 레지스트리 파일 확인
  if [ -f "${REGISTRY_FILE}" ]; then
    log_success "레지스트리 파일이 존재합니다."
    
    # 항목 개수 확인
    local item_count=$(jq '. | length' "${REGISTRY_FILE}")
    if [ "${item_count}" -eq 3 ]; then
      log_success "레지스트리 파일에 정확히 3개의 항목이 있습니다."
    else
      log_error "레지스트리 파일에 3개의 항목이 없습니다. 실제 항목 수: ${item_count}"
      cat "${REGISTRY_FILE}"
      return 1
    fi
    
    # 새 프로젝트 확인
    local new_project=$(jq '.[] | select(.name == "'"${LARAVEL_PROJECT_NAME}"'") | .name' "${REGISTRY_FILE}")
    if [ -n "${new_project}" ]; then
      log_success "새 Laravel 프로젝트가 레지스트리에 추가되었습니다: ${new_project}"
      
      # should_install 값 확인
      local should_install=$(jq '.[] | select(.name == "'"${LARAVEL_PROJECT_NAME}"'") | .should_install' "${REGISTRY_FILE}")
      if [ "${should_install}" = "false" ]; then
        log_success "should_install 값이 올바르게 false로 설정되었습니다."
      else
        log_error "should_install 값이 false가 아닙니다: ${should_install}"
        cat "${REGISTRY_FILE}"
        return 1
      fi
    else
      log_error "새 Laravel 프로젝트가 레지스트리에 추가되지 않았습니다."
      cat "${REGISTRY_FILE}"
      return 1
    fi
  else
    log_error "레지스트리 파일이 존재하지 않습니다."
    return 1
  fi
}

# 최종 레지스트리 항목 수 확인 테스트
check_final_registry_entries() {
  log_info "=== 최종 레지스트리 항목 수 검증 ==="
  local expected_count=5  # 초기 1개 + WordPress 2개 + Laravel 2개
  local final_count=$(grep -o '"name"' "$REGISTRY_FILE" | wc -l | tr -d ' ')
  
  if [ "$final_count" -eq "$expected_count" ]; then
    test_result "최종_레지스트리_항목_수" "pass" "최종 레지스트리에 예상대로 $expected_count개의 항목이 있습니다."
  else
    test_result "최종_레지스트리_항목_수" "fail" "최종 레지스트리에 예상($expected_count)과 다른 항목 수($final_count)가 있습니다."
  fi
}

# 테스트 실행
test_wordpress_registry_update  # WordPress 표준 테스트
test_laravel_registry_update    # Laravel 표준 테스트
check_final_registry_entries    # 최종 레지스트리 항목 수 검증

# 테스트 종료 시간 기록 및 소요 시간 계산
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# 테스트 결과 요약
log_info "===================================================="
log_info "테스트 결과 요약"
log_info "===================================================="
log_info "총 테스트 수: $TESTS_TOTAL"
log_info "통과한 테스트: $TESTS_PASSED"
log_error "실패한 테스트: $TESTS_FAILED"
log_info "테스트 소요 시간: ${DURATION}초"
log_info "===================================================="

if [ $TESTS_FAILED -eq 0 ]; then
  log_info "✅ 모든 테스트가 성공적으로 통과했습니다!"
else
  log_error "❌ 일부 테스트에 실패했습니다. 자세한 내용은 로그를 확인하세요."
fi

log_info "테스트 디렉토리: $TEST_DIR"
log_info "테스트 정리가 필요하면: rm -rf \"$TEST_DIR\""

# 테스트 성공 여부에 따른 종료 코드 설정
if [ $TESTS_FAILED -eq 0 ]; then
  exit 0
else
  exit 1
fi 