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

# 스크립트 사용법 출력
show_usage() {
  echo "DDEV 프로젝트 설치 스크립트"
  echo ""
  echo "사용법: $0 [옵션]"
  echo ""
  echo "옵션:"
  echo "  -t, --type       프로젝트 유형 (wordpress 또는 laravel) [필수]"
  echo "  -n, --name       프로젝트 이름 [필수]"
  echo "  -d, --directory  프로젝트 설치 디렉토리 (기본값: 현재 디렉토리 내의 프로젝트 이름)"
  echo "  -h, --help       도움말 표시"
  echo ""
  echo "예시:"
  echo "  $0 --type wordpress --name my-wp-site"
  echo "  $0 -t laravel -n my-laravel-app -d /path/to/projects"
}

# DDEV 설치 확인 및 설치
check_or_install_ddev() {
  if ! command -v ddev &> /dev/null; then
    log_warning "DDEV가 설치되어 있지 않습니다. 설치를 시작합니다..."
    
    # OS 확인
    if [[ "$OSTYPE" == "darwin"* ]]; then
      # macOS
      if command -v brew &> /dev/null; then
        log_info "Homebrew를 사용하여 DDEV 설치 중..."
        brew install ddev/ddev/ddev
      else
        log_error "Homebrew가 설치되어 있지 않습니다. https://brew.sh/ 에서 Homebrew를 설치한 후 다시 시도해주세요."
        exit 1
      fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
      # Linux
      log_info "Linux에서 DDEV 설치 중..."
      curl -fsSL https://raw.githubusercontent.com/ddev/ddev/master/scripts/install_ddev.sh | bash
    elif [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "cygwin"* ]]; then
      # Windows with Git Bash or similar
      log_error "Windows에서는 Chocolatey를 사용하여 DDEV를 설치해주세요: choco install ddev"
      log_error "자세한 내용은 https://ddev.readthedocs.io/en/stable/users/install/ddev-installation/ 를 참조하세요."
      exit 1
    else
      log_error "지원되지 않는 운영체제입니다."
      exit 1
    fi
    
    # DDEV 설치 확인
    if ! command -v ddev &> /dev/null; then
      log_error "DDEV 설치에 실패했습니다. 수동으로 설치해주세요."
      log_error "설치 방법: https://ddev.readthedocs.io/en/stable/users/install/ddev-installation/"
      exit 1
    fi
    
    log_info "DDEV가 성공적으로 설치되었습니다!"
  else
    log_info "DDEV가 이미 설치되어 있습니다. 버전: $(ddev --version)"
  fi
}

# Docker 실행 확인
check_docker() {
  if ! docker info &> /dev/null; then
    log_error "Docker가 실행되고 있지 않습니다. Docker를 시작한 후 다시 시도해주세요."
    exit 1
  fi
  log_info "Docker가 실행 중입니다."
}

# 프로젝트 생성
create_project() {
  local project_type=$1
  local project_name=$2
  local project_dir=$3
  
  # 프로젝트 디렉토리 생성
  mkdir -p "$project_dir"
  cd "$project_dir" || { log_error "디렉토리 $project_dir로 이동할 수 없습니다."; exit 1; }
  
  log_info "프로젝트 디렉토리: $project_dir"
  
  # 설정 파일 복사 경로
  local script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
  local settings_dir="$script_dir/ddev-setup-settings/$project_type"
  
  if [ ! -d "$settings_dir" ]; then
    log_error "설정 디렉토리를 찾을 수 없습니다: $settings_dir"
    exit 1
  fi
  
  # DDEV 프로젝트 설정
  log_info "DDEV 프로젝트 ($project_type) 설정 중..."
  
  # .ddev 디렉토리 생성
  mkdir -p .ddev
  
  # config.yaml 복사
  log_info "DDEV 설정 파일 복사 중..."
  cp "$settings_dir/config.yaml" .ddev/config.yaml
  
  # 프로젝트 이름 업데이트
  sed -i.bak "s/name: .*-site/name: $project_name/" .ddev/config.yaml && rm .ddev/config.yaml.bak
  
  # DDEV 시작
  log_info "DDEV 프로젝트 시작 중..."
  ddev start
  
  # 프로젝트 상태 확인
  log_info "프로젝트 상태:"
  ddev describe
  
  # 접속 정보 표시
  local url=$(ddev describe | grep -o 'https://.*\.ddev\.site' | head -n 1)
  
  log_info "프로젝트 설치가 완료되었습니다!"
  log_info "접속 URL: $url"
  log_info ""
  log_info "유용한 명령어:"
  log_info "  ddev start       - 프로젝트 시작"
  log_info "  ddev stop        - 프로젝트 중지"
  log_info "  ddev describe    - 프로젝트 정보 확인"
  
  # 프로젝트 유형별 추가 정보
  if [ "$project_type" == "wordpress" ]; then
    log_info "WordPress 관리자 페이지: $url/wp-admin/"
  elif [ "$project_type" == "laravel" ]; then
    log_info "Laravel Artisan 명령 실행: ddev exec php artisan"
  fi
}

# 메인 스크립트 시작

# 기본값 설정
PROJECT_TYPE=""
PROJECT_NAME=""
PROJECT_DIR=""

# 명령줄 인수 파싱
while (( "$#" )); do
  case "$1" in
    -t|--type)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        PROJECT_TYPE=$2
        shift 2
      else
        log_error "오류: --type 인수 누락"
        show_usage
        exit 1
      fi
      ;;
    -n|--name)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        PROJECT_NAME=$2
        shift 2
      else
        log_error "오류: --name 인수 누락"
        show_usage
        exit 1
      fi
      ;;
    -d|--directory)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        PROJECT_DIR=$2
        shift 2
      else
        log_error "오류: --directory 인수 누락"
        show_usage
        exit 1
      fi
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

# 필수 인수 확인
if [ -z "$PROJECT_TYPE" ]; then
  log_error "프로젝트 유형을 지정해야 합니다."
  show_usage
  exit 1
fi

if [ -z "$PROJECT_NAME" ]; then
  log_error "프로젝트 이름을 지정해야 합니다."
  show_usage
  exit 1
fi

# 지원되는 프로젝트 유형 확인
if [ "$PROJECT_TYPE" != "wordpress" ] && [ "$PROJECT_TYPE" != "laravel" ]; then
  log_error "지원되지 않는 프로젝트 유형입니다: $PROJECT_TYPE"
  log_error "지원되는 유형: wordpress, laravel"
  exit 1
fi

# 프로젝트 디렉토리 설정
if [ -z "$PROJECT_DIR" ]; then
  PROJECT_DIR="$(pwd)/$PROJECT_NAME"
fi

# 설치 시작
log_info "DDEV '$PROJECT_TYPE' 프로젝트 '$PROJECT_NAME' 설치를 시작합니다."

# DDEV 및 Docker 확인
check_or_install_ddev
check_docker

# 프로젝트 생성
create_project "$PROJECT_TYPE" "$PROJECT_NAME" "$PROJECT_DIR" 