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
  echo "WordPress DDEV 프로젝트 설치 스크립트"
  echo ""
  echo "사용법: $0 [옵션]"
  echo ""
  echo "옵션:"
  echo "  -n, --name       프로젝트 이름 [필수]"
  echo "  -d, --directory  프로젝트 설치 디렉토리 (기본값: 현재 디렉토리 내의 ddev-projects/프로젝트이름)"
  echo "  -h, --help       도움말 표시"
  echo "      --dry-run    실제 설치 없이 테스트 (테스트 목적)"
  echo "  -i, --install    WordPress 자동 설치"
  echo "  -t, --title      사이트 제목 (기본값: WordPress 사이트)"
  echo "  -u, --user       관리자 사용자명 (기본값: admin)"
  echo "  -p, --pass       관리자 비밀번호 (기본값: 임의 생성)"
  echo "  -e, --email      관리자 이메일 (기본값: admin@example.com)"
  echo ""
  echo "예시:"
  echo "  $0 --name my-wp-site"
  echo "  $0 -n my-wp-site -d /path/to/projects"
  echo "  $0 -n my-wp-site -i -t \"내 워드프레스 사이트\" -u admin -p password -e admin@example.com"
}

# DDEV 설치 확인 및 설치
check_or_install_ddev() {
  # dry run 모드에서는 이 단계를 건너뜁니다
  if [ "$DRY_RUN" == "true" ]; then
    log_info "[DRY RUN] DDEV 설치 확인 단계를 건너뜁니다."
    return 0
  fi

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
  # dry run 모드에서는 이 단계를 건너뜁니다
  if [ "$DRY_RUN" == "true" ]; then
    log_info "[DRY RUN] Docker 실행 확인 단계를 건너뜁니다."
    return 0
  fi

  if ! docker info &> /dev/null; then
    log_error "Docker가 실행되고 있지 않습니다. Docker를 시작한 후 다시 시도해주세요."
    exit 1
  fi
  log_info "Docker가 실행 중입니다."
}

# WordPress 자동 설치
install_wordpress() {
  local project_name=$1
  local site_title=$2
  local admin_user=$3
  local admin_pass=$4
  local admin_email=$5
  
  if [ "$DRY_RUN" == "true" ]; then
    log_info "[DRY RUN] WordPress 자동 설치를 시뮬레이션합니다."
    log_info "[DRY RUN] 사이트 제목: $site_title"
    log_info "[DRY RUN] 관리자 사용자: $admin_user"
    log_info "[DRY RUN] 관리자 이메일: $admin_email"
    return 0
  fi
  
  log_info "WordPress 자동 설치를 시작합니다..."
  
  # 현재 디렉토리 확인
  local current_dir=$(pwd)
  
  # 프로젝트 디렉토리로 이동
  cd "$PROJECT_DIR" || { log_error "디렉토리 $PROJECT_DIR로 이동할 수 없습니다."; exit 1; }
  
  # WordPress 설치 명령 실행
  log_info "WordPress 코어 파일 다운로드 및 설치 중..."
  
  # 단일 명령으로 WordPress 설치 (오류 처리 개선)
  if ddev exec bash -c "cd /var/www/html && wp core download --locale=ko_KR && wp config create --dbname=db --dbuser=db --dbpass=db --dbhost=db && wp core install --url=https://$project_name.ddev.site --title='$site_title' --admin_user='$admin_user' --admin_password='$admin_pass' --admin_email='$admin_email'"; then
    log_info "WordPress 코어 파일 설치가 완료되었습니다!"
    
    # 추가 설정
    log_info "추가 설정을 적용 중..."
    ddev exec bash -c "wp language core install ko_KR --activate && \
                      wp option update WPLANG ko_KR && \
                      wp plugin delete hello-dolly && \
                      wp plugin delete akismet && \
                      wp rewrite structure '/%postname%/' && \
                      wp option update timezone_string 'Asia/Seoul'"
    
    log_info "WordPress 설치가 완료되었습니다!"
    log_info "관리자 페이지: https://$project_name.ddev.site/wp-admin/"
    log_info "사용자명: $admin_user"
    log_info "비밀번호: $admin_pass"
  else
    log_error "WordPress 설치 중 오류가 발생했습니다."
  fi
  
  # 기존 디렉토리로 돌아가기
  cd "$current_dir" || { log_error "디렉토리 $current_dir로 이동할 수 없습니다."; exit 1; }
}

# WordPress 프로젝트 생성
create_wordpress_project() {
  local project_name=$1
  local project_dir=$2
  
  # 스크립트 디렉토리 가져오기
  local script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
  
  # 프로젝트 디렉토리 생성
  if [ "$DRY_RUN" == "true" ]; then
    log_info "[DRY RUN] 프로젝트 디렉토리를 생성합니다: $project_dir"
  else
    mkdir -p "$project_dir"
    cd "$project_dir" || { log_error "디렉토리 $project_dir로 이동할 수 없습니다."; exit 1; }
  fi
  
  log_info "프로젝트 디렉토리: $project_dir"
  
  # 설정 파일 복사 경로
  local settings_dir="$script_dir"
  
  if [ ! -d "$settings_dir" ] && [ "$DRY_RUN" != "true" ]; then
    log_error "설정 디렉토리를 찾을 수 없습니다: $settings_dir"
    exit 1
  fi
  
  # DDEV 프로젝트 설정
  log_info "WordPress DDEV 프로젝트 설정 중..."
  
  if [ "$DRY_RUN" == "true" ]; then
    log_info "[DRY RUN] .ddev 디렉토리를 생성합니다."
    log_info "[DRY RUN] public 디렉토리를 생성합니다."
    log_info "[DRY RUN] WordPress 기본 파일을 생성합니다."
    log_info "[DRY RUN] $settings_dir/config.yaml 파일을 복사하고 프로젝트 이름을 $project_name로 설정합니다."
    log_info "[DRY RUN] ddev start 명령을 실행합니다."
    log_info "[DRY RUN] 프로젝트를 project-list.json에 추가합니다."
  else
    # .ddev 디렉토리 생성
    mkdir -p .ddev
    
    # public 디렉토리 생성
    mkdir -p public
    
    # WordPress 기본 파일 생성
    echo "<?php echo 'WordPress 프로젝트 시작'; ?>" > public/index.php
    touch public/.gitkeep
    
    # config.yaml 복사
    log_info "DDEV 설정 파일 복사 중..."
    cp "$settings_dir/config.yaml" .ddev/config.yaml
    
    # 프로젝트 이름 업데이트
    sed -i.bak "s/name: .*-site/name: $project_name/" .ddev/config.yaml && rm .ddev/config.yaml.bak
    
    # config.yaml 파일에 hooks 섹션이 이미 있는지 확인
    if grep -q "hooks:" .ddev/config.yaml; then
      log_info "기존 hooks 설정을 수정합니다..."
      
      # 기존 hooks 섹션에 wp-cli 다운로드 명령어 추가
      if ! grep -q "wget -O /usr/local/bin/wp" .ddev/config.yaml; then
        sed -i.bak '/hooks:/,/post-start:/s/post-start:/post-start:\n    - exec: wget -O \/usr\/local\/bin\/wp https:\/\/raw.githubusercontent.com\/wp-cli\/builds\/gh-pages\/phar\/wp-cli.phar \&\& chmod +x \/usr\/local\/bin\/wp/' .ddev/config.yaml && rm .ddev/config.yaml.bak
      fi
    else
      # hooks 설정이 없는 경우 추가
      log_info "wp-cli 설정 추가 중..."
      echo "
webimage_extra_packages:
  - mariadb-client
  - bash-completion
  - jq
  - less
  - time

hooks:
  post-start:
    - exec: wget -O /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x /usr/local/bin/wp" >> .ddev/config.yaml
    fi
    
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
    
    # WordPress 관리자 페이지 정보 표시
    log_info "WordPress 관리자 페이지: $url/wp-admin/"
    
    # WordPress 자동 설치가 활성화된 경우
    if [ "$AUTO_INSTALL" == "true" ]; then
      install_wordpress "$project_name" "$SITE_TITLE" "$ADMIN_USER" "$ADMIN_PASS" "$ADMIN_EMAIL"
    fi
    
    # 프로젝트를 ddev-projects 목록에 추가
    add_to_project_list "$project_name" "$script_dir"
  fi
}

# 프로젝트를 project-list.json에 추가
add_to_project_list() {
  local project_name=$1
  local script_dir=$2
  local project_list_file="$ROOT_DIR/ddev-projects/project-list.json"
  
  if [ "$DRY_RUN" == "true" ]; then
    log_info "[DRY RUN] 프로젝트 '$project_name'를 프로젝트 목록 파일에 추가합니다: $project_list_file"
    return 0
  fi
  
  # ddev-projects 디렉토리 확인 및 생성
  mkdir -p "$ROOT_DIR/ddev-projects"
  log_info "프로젝트 목록 디렉토리: $ROOT_DIR/ddev-projects"
  
  # project-list.json 파일이 없으면 생성
  if [ ! -f "$project_list_file" ]; then
    echo '[]' > "$project_list_file"
    log_info "프로젝트 목록 파일 생성: $project_list_file"
  fi
  
  # 현재 프로젝트 목록 가져오기
  local projects=$(cat "$project_list_file")
  log_info "현재 프로젝트 목록: $projects"
  
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
    
    echo "$updated_projects" > "$project_list_file"
    log_info "프로젝트 '$project_name'를 프로젝트 목록에 추가했습니다. 업데이트된 목록: $updated_projects"
  fi
}

# 임의 비밀번호 생성
generate_password() {
  local length=12
  local password=$(LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*()_+' < /dev/urandom | head -c $length)
  echo "$password"
}

# 메인 스크립트 시작

# 기본값 설정
PROJECT_NAME="wp-site"  # 기본 프로젝트 이름
PROJECT_DIR=""
DRY_RUN="false"
AUTO_INSTALL="true"  # 기본적으로 자동 설치 활성화
SITE_TITLE="WordPress 사이트"
ADMIN_USER="admin"
ADMIN_PASS="admin"  # 기본 관리자 비밀번호
ADMIN_EMAIL="admin@example.com"

# 명령줄 인수 파싱
while (( "$#" )); do
  case "$1" in
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
    -i|--install)
      AUTO_INSTALL="true"
      shift
      ;;
    -t|--title)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        SITE_TITLE=$2
        shift 2
      else
        log_error "오류: --title 인수 누락"
        show_usage
        exit 1
      fi
      ;;
    -u|--user)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        ADMIN_USER=$2
        shift 2
      else
        log_error "오류: --user 인수 누락"
        show_usage
        exit 1
      fi
      ;;
    -p|--pass)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        ADMIN_PASS=$2
        shift 2
      else
        log_error "오류: --pass 인수 누락"
        show_usage
        exit 1
      fi
      ;;
    -e|--email)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        ADMIN_EMAIL=$2
        shift 2
      else
        log_error "오류: --email 인수 누락"
        show_usage
        exit 1
      fi
      ;;
    --dry-run)
      DRY_RUN="true"
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

# 필수 인수 확인
if [ -z "$PROJECT_NAME" ]; then
  log_error "프로젝트 이름을 지정해야 합니다."
  show_usage
  exit 1
fi

# 스크립트 디렉토리 가져오기
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ROOT_DIR="$( cd "$SCRIPT_DIR/../.." && pwd )"

# 프로젝트 디렉토리 설정
if [ -z "$PROJECT_DIR" ]; then
  PROJECT_DIR="$ROOT_DIR/ddev-projects/$PROJECT_NAME"
fi

# 설치 시작
if [ "$DRY_RUN" == "true" ]; then
  log_info "[DRY RUN] WordPress DDEV 프로젝트 '$PROJECT_NAME' 설치를 시뮬레이션합니다."
else
  log_info "WordPress DDEV 프로젝트 '$PROJECT_NAME' 설치를 시작합니다."
fi

# WordPress 자동 설치 옵션 출력
if [ "$AUTO_INSTALL" == "true" ] && [ "$DRY_RUN" != "true" ]; then
  log_info "WordPress 자동 설치가 활성화되었습니다."
  log_info "사이트 제목: $SITE_TITLE"
  log_info "관리자 사용자: $ADMIN_USER"
  log_info "관리자 비밀번호: $ADMIN_PASS"
  log_info "관리자 이메일: $ADMIN_EMAIL"
fi

# DDEV 및 Docker 확인
check_or_install_ddev
check_docker

# WordPress 프로젝트 생성
create_wordpress_project "$PROJECT_NAME" "$PROJECT_DIR"

if [ "$DRY_RUN" == "true" ]; then
  log_info "[DRY RUN] 설치 시뮬레이션이 완료되었습니다. 실제 설치는 --dry-run 옵션을 제거하세요."
fi 