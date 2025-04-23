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
  echo "  -r, --repo       GitHub 레포지토리 URL (예: https://github.com/username/repo.git)"
  echo "  -c, --catalog    카탈로그 파일 경로 (기본값: projects-env/wordpress-project-catalog.json)"
  echo "  -v, --version    워드프레스 버전 (기본값: latest)"
  echo "      --registry-only  레지스트리 업데이트 모드로 실행"
  echo "      --no-install     설치하지 않고 레지스트리만 업데이트 (should_install=false로 설정)"
  echo ""
  echo "예시:"
  echo "  $0 --name my-wp-site"
  echo "  $0 -n my-wp-site -d /path/to/projects"
  echo "  $0 -n my-wp-site -i -t \"내 워드프레스 사이트\" -u admin -p password -e admin@example.com"
  echo "  $0 -n my-wp-site -r https://github.com/username/wp-template.git"
  echo "  $0 -n my-wp-site --no-install     # 설치하지 않고 레지스트리에만 추가"
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
  
  # 카탈로그 파일 경로 설정
  local catalog_file="$ROOT_DIR/$CATALOG_PATH"
  
  if [ "$DRY_RUN" == "true" ]; then
    log_info "[DRY RUN] 프로젝트 '$project_name'를 프로젝트 목록 파일에 추가합니다: $catalog_file"
    return 0
  fi
  
  # 카탈로그 파일 디렉토리 확인 및 생성
  mkdir -p "$(dirname "$catalog_file")"
  log_info "프로젝트 카탈로그 파일: $catalog_file"
  
  # 카탈로그 파일이 없으면 생성
  if [ ! -f "$catalog_file" ]; then
    echo '[]' > "$catalog_file"
    log_info "프로젝트 카탈로그 파일 생성: $catalog_file"
  fi
  
  # 현재 프로젝트 목록 가져오기
  local projects=$(cat "$catalog_file")
  
  # 현재 날짜
  local current_date=$(date +%Y-%m-%d)
  
  # 고유 ID 생성
  local project_id="$project_name-$(date +%s | cut -c7-10)"
  
  # WordPress 버전 가져오기
  local framework_version="$WP_VERSION"
  if [ -z "$framework_version" ]; then
    framework_version="latest"
  fi
  
  # 프로젝트 이름이 이미 목록에 있는지 확인
  if echo "$projects" | grep -q "\"name\":\"$project_name\""; then
    # 이미 카탈로그에 있는 프로젝트인 경우 add_to_catalog 값 확인
    local add_to_catalog=$(echo "$projects" | grep -o "{[^{]*\"name\":\"$project_name\"[^}]*}" | grep -o "\"add_to_catalog\":[^,}]*" | cut -d':' -f2 | tr -d ' ')
    
    log_info "프로젝트 '$project_name'에 대한 add_to_catalog 값: $add_to_catalog"
    
    if [ "$add_to_catalog" == "false" ]; then
      log_info "프로젝트 '$project_name'의 카탈로그 추가 설정이 false입니다. 카탈로그에 추가하지 않습니다."
      return 0
    else
      log_info "프로젝트 '$project_name'는 이미 프로젝트 카탈로그에 있습니다."
    fi
  
    log_info "프로젝트 '$project_name'을 카탈로그에 새로 추가합니다."
    
    # JSON 파싱 및 수정
    if [ "$projects" == "[]" ]; then
      # 빈 목록인 경우
      cat > "$catalog_file" << EOF
[
  {
    "id": "$project_id",
    "name": "$project_name",
    "type": "wordpress",
    "framework": "wordpress",
    "framework_version": "$framework_version",
    "repoUrl": "$REPO_URL",
    "branch": "main",
    "memo": "WordPress 프로젝트",
    "created_at": "$current_date",
    "last_updated": "$current_date",
    "add_to_catalog": true
  }
]
EOF
    else
      # 마지막 닫는 대괄호 제거하고 새 항목 추가
      local temp_file=$(mktemp)
      sed '$ s/]$/,/' "$catalog_file" > "$temp_file"
      cat >> "$temp_file" << EOF
  {
    "id": "$project_id",
    "name": "$project_name",
    "type": "wordpress",
    "framework": "wordpress",
    "framework_version": "$framework_version",
    "repoUrl": "$REPO_URL",
    "branch": "main",
    "memo": "WordPress 프로젝트",
    "created_at": "$current_date",
    "last_updated": "$current_date",
    "add_to_catalog": true
  }
]
EOF
      mv "$temp_file" "$catalog_file"
    fi
    
    log_info "프로젝트 '$project_name'를 프로젝트 카탈로그에 추가했습니다."
  fi
  
  # 추가: ddev-projects/ddev-project-registry.json 파일에 자세한 정보 추가
  update_project_registry "$project_name" "$project_dir" "$SHOULD_INSTALL"
}

# 프로젝트 레지스트리 파일 업데이트 함수
update_project_registry() {
  local project_name="$1"
  local project_dir="$2"
  local framework_version="${3:-latest}"
  local project_id="${project_name}-$(( RANDOM % 10000 ))"
  local current_date=$(date +%Y-%m-%d)
  local local_url="https://${project_name}.ddev.site"
  
  # 레지스트리 파일 위치 확인
  if [ -z "$DDEV_PROJECT_REGISTRY" ]; then
    DDEV_PROJECT_REGISTRY="${ROOT_DIR}/ddev-projects/ddev-project-registry.json"
  fi
  
  log_info "프로젝트 레지스트리 경로: $DDEV_PROJECT_REGISTRY"
  
  # 레지스트리 디렉토리 확인 및 생성
  local registry_dir=$(dirname "$DDEV_PROJECT_REGISTRY")
  if [ ! -d "$registry_dir" ]; then
    mkdir -p "$registry_dir"
  fi
  
  # 레지스트리 파일이 존재하지 않으면 새로 생성
  if [ ! -f "$DDEV_PROJECT_REGISTRY" ]; then
    log_info "레지스트리 파일이 존재하지 않습니다. 새로 생성합니다."
    echo "[]" > "$DDEV_PROJECT_REGISTRY"
  fi
  
  # 설치 상태 설정 (--no-install 옵션에 따라)
  local installed_status=true
  if [ "$NO_INSTALL" = true ]; then
    installed_status=false
  fi
  
  # 임시 파일에 새 프로젝트 정보 추가
  local temp_file=$(mktemp)
  
  # 레지스트리 파일이 비어있는지 확인
  if [ "$(cat "$DDEV_PROJECT_REGISTRY")" = "[]" ]; then
    # 빈 레지스트리에 첫 번째 항목 추가
    cat > "$temp_file" << EOF
[
  {
    "id": "${project_id}",
    "name": "${project_name}",
    "type": "wordpress",
    "framework": "wordpress",
    "framework_version": "${framework_version}",
    "repoUrl": "",
    "branch": "main",
    "local_url": "${local_url}",
    "directory": "${project_dir}",
    "db_name": "db",
    "db_user": "db",
    "php_version": "8.1",
    "webserver_type": "nginx-fpm",
    "should_install": ${installed_status},
    "memo": "WordPress 사이트",
    "created_at": "${current_date}",
    "last_updated": "${current_date}",
    "last_used": "${current_date}"
  }
]
EOF
  else
    # 기존 레지스트리에 항목 추가
    jq --arg id "${project_id}" \
       --arg name "${project_name}" \
       --arg version "${framework_version}" \
       --arg url "${local_url}" \
       --arg dir "${project_dir}" \
       --arg date "${current_date}" \
       --argjson installed "${installed_status}" \
       '. += [{
            "id": $id,
            "name": $name,
            "type": "wordpress",
            "framework": "wordpress",
            "framework_version": $version,
            "repoUrl": "",
            "branch": "main",
            "local_url": $url,
            "directory": $dir,
            "db_name": "db",
            "db_user": "db",
            "php_version": "8.1",
            "webserver_type": "nginx-fpm",
            "should_install": $installed,
            "memo": "WordPress 사이트",
            "created_at": $date,
            "last_updated": $date,
            "last_used": $date
        }]' "$DDEV_PROJECT_REGISTRY" > "$temp_file"
  fi
  
  # 임시 파일을 레지스트리 파일로 이동
  mv "$temp_file" "$DDEV_PROJECT_REGISTRY"
  
  log_info "프로젝트 '${project_name}'이(가) 레지스트리에 추가되었습니다."
  
  # 디버깅을 위해 레지스트리 내용 출력
  if [ "$DEBUG" = true ]; then
    log_debug "업데이트된 레지스트리 내용:"
    cat "$DDEV_PROJECT_REGISTRY"
  fi
}

# 임의 비밀번호 생성
generate_password() {
  local length=12
  local password=$(LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*()_+' < /dev/urandom | head -c $length)
  echo "$password"
}

# GitHub 레포지토리에서 WordPress 프로젝트 복제
clone_from_repository() {
  local project_name=$1
  local project_dir=$2
  local repo_url=$3
  
  # 스크립트 디렉토리 가져오기
  local script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
  
  if [ "$DRY_RUN" == "true" ]; then
    log_info "[DRY RUN] GitHub 레포지토리 '$repo_url'에서 프로젝트를 복제합니다."
    log_info "[DRY RUN] 복제 대상 디렉토리: $project_dir"
    return 0
  fi
  
  # 이미 디렉토리가 존재하는지 확인
  if [ -d "$project_dir" ]; then
    log_warning "디렉토리 '$project_dir'가 이미 존재합니다."
    read -p "기존 디렉토리를 삭제하고 계속하시겠습니까? (y/n): " confirm
    if [ "$confirm" != "y" ]; then
      log_error "설치가 취소되었습니다."
      exit 1
    fi
    rm -rf "$project_dir"
  fi
  
  log_info "GitHub 레포지토리 '$repo_url'에서 프로젝트를 복제합니다..."
  mkdir -p "$(dirname "$project_dir")"
  
  # GitHub 레포지토리 복제
  if git clone "$repo_url" "$project_dir"; then
    log_info "레포지토리 복제가 완료되었습니다!"
    
    # 프로젝트 디렉토리로 이동
    cd "$project_dir" || { log_error "디렉토리 $project_dir로 이동할 수 없습니다."; exit 1; }
    
    # .ddev 디렉토리가 있는지 확인
    if [ ! -d ".ddev" ]; then
      log_warning ".ddev 디렉토리가 존재하지 않습니다. DDEV 설정을 생성합니다."
      mkdir -p .ddev
      
      # config.yaml 복사
      log_info "DDEV 설정 파일 복사 중..."
      cp "$script_dir/config.yaml" .ddev/config.yaml
      
      # 프로젝트 이름 업데이트
      sed -i.bak "s/name: .*-site/name: $project_name/" .ddev/config.yaml && rm .ddev/config.yaml.bak
      
      # hooks 설정 추가
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
    else
      # 프로젝트 이름 업데이트
      log_info "DDEV 설정의 프로젝트 이름 업데이트 중..."
      sed -i.bak "s/name: .*/name: $project_name/" .ddev/config.yaml && rm .ddev/config.yaml.bak
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
    
    # WordPress 자동 설치가 활성화된 경우
    if [ "$AUTO_INSTALL" == "true" ]; then
      install_wordpress "$project_name" "$SITE_TITLE" "$ADMIN_USER" "$ADMIN_PASS" "$ADMIN_EMAIL"
    fi
    
    # 프로젝트를 ddev-projects 목록에 추가
    add_to_project_list "$project_name" "$script_dir"
  else
    log_error "GitHub 레포지토리 복제 중 오류가 발생했습니다."
    exit 1
  fi
}

# 메인 스크립트 시작

# 기본값 설정
PROJECT_NAME=""  # 필수 값으로 변경
PROJECT_DIR=""
DRY_RUN="false"
REGISTRY_ONLY="false"
SHOULD_INSTALL="true"  # 기본적으로 설치 수행
WP_VERSION="latest"
CATALOG_PATH="projects-env/wordpress-project-catalog.json"  # 기본 카탈로그 파일 경로

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
    -v|--version)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        WP_VERSION=$2
        shift 2
      else
        log_error "오류: --version 인수 누락"
        show_usage
        exit 1
      fi
      ;;
    -r|--repo)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        REPO_URL=$2
        shift 2
      else
        log_error "오류: --repo 인수 누락"
        show_usage
        exit 1
      fi
      ;;
    -c|--catalog)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        CATALOG_PATH=$2
        shift 2
      else
        log_error "오류: --catalog 인수 누락"
        show_usage
        exit 1
      fi
      ;;
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    --registry-only)
      REGISTRY_ONLY="true"
      shift
      ;;
    --no-install)
      SHOULD_INSTALL="false"
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
  log_error "프로젝트 이름을 지정해야 합니다. (-n 또는 --name 옵션 사용)"
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

# 레지스트리 파일 경로 설정
if [ -n "$DDEV_PROJECT_REGISTRY" ]; then
  REGISTRY_FILE="$DDEV_PROJECT_REGISTRY"
else
  REGISTRY_FILE="$ROOT_DIR/ddev-projects/ddev-project-registry.json"
fi

# 메인 로직
if [ "$REGISTRY_ONLY" == "true" ]; then
  log_info "레지스트리 업데이트 모드로 실행합니다."
  update_project_registry "$PROJECT_NAME" "$PROJECT_DIR" "$SHOULD_INSTALL"
  exit 0
fi

# 설치 시작
if [ "$DRY_RUN" == "true" ]; then
  log_info "[DRY RUN] WordPress DDEV 프로젝트 '$PROJECT_NAME' 설치를 시뮬레이션합니다."
else
  if [ "$SHOULD_INSTALL" == "true" ]; then
    log_info "WordPress DDEV 프로젝트 '$PROJECT_NAME' 설치를 시작합니다."
  else
    log_info "WordPress DDEV 프로젝트 '$PROJECT_NAME'의 설치를 건너뛰고 레지스트리에만 추가합니다."
    update_project_registry "$PROJECT_NAME" "$PROJECT_DIR" "$SHOULD_INSTALL"
    exit 0
  fi
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

# WordPress 프로젝트 생성 또는 복제
if [ -n "$REPO_URL" ]; then
  # GitHub 레포지토리에서 복제
  clone_from_repository "$PROJECT_NAME" "$PROJECT_DIR" "$REPO_URL"
else
  # 새로운 WordPress 프로젝트 생성
  create_wordpress_project "$PROJECT_NAME" "$PROJECT_DIR"
fi

if [ "$DRY_RUN" == "true" ]; then
  log_info "[DRY RUN] 설치 시뮬레이션이 완료되었습니다. 실제 설치는 --dry-run 옵션을 제거하세요."
fi 