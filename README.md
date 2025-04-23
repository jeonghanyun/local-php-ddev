# DDEV 프로젝트 관리 스크립트

이 저장소는 DDEV를 사용한 WordPress 및 Laravel 개발 환경 설정 및 관리를 위한 스크립트를 제공합니다.

## 기능

- WordPress 및 Laravel 프로젝트 자동 설치
- 프로젝트 URL 관리
- 설정 파일 자동화

## 요구 사항

- Docker
- DDEV (자동으로 설치됨)

## 설치 및 사용

### 프로젝트 설치

메인 설치 스크립트를 사용하여 WordPress 또는 Laravel 프로젝트를 설치할 수 있습니다:

```bash
./install.sh --type wordpress --name my-wordpress-site
./install.sh --type laravel --name my-laravel-app
```

### 설치 옵션

```
옵션:
  -t, --type       프로젝트 유형 (wordpress 또는 laravel) [필수]
  -n, --name       프로젝트 이름 [필수]
  -d, --directory  프로젝트 설치 디렉토리 (기본값: 현재 디렉토리 내의 ddev-projects/프로젝트이름)
  -h, --help       도움말 표시
      --dry-run    실제 설치 없이 테스트 (테스트 목적)
```

### 개별 설치 스크립트 사용

WordPress 및 Laravel 프로젝트를 위한 개별 설치 스크립트도 직접 사용할 수 있습니다:

#### WordPress 설치

```bash
./ddev-setup-settings/wordpress/install-wordpress.sh -n my-wordpress-site
```

#### Laravel 설치

```bash
./ddev-setup-settings/laravel/install-laravel.sh -n my-laravel-app
```

### URL 관리

모든 또는 특정 DDEV 프로젝트 URL을 표시합니다:

```bash
# 모든 프로젝트 URL 표시
./urls.sh

# 실행 중인 프로젝트 URL만 표시
./urls.sh -r

# 특정 프로젝트 URL 표시
./urls.sh -n my-project-name
```

## 유지 관리

프로젝트 설정 파일은 `ddev-setup-settings` 디렉토리에 저장됩니다:
- WordPress 설정: `ddev-setup-settings/wordpress/`
- Laravel 설정: `ddev-setup-settings/laravel/`

## 개요

DDEV는 로컬 개발 환경을 쉽게 설정할 수 있게 해주는 오픈 소스 툴입니다. 이 저장소는 다양한 DDEV 설정과 프로젝트 예제를 포함하고 있습니다.

## 구조

- `ddev-projects/`: DDEV 기반 프로젝트들
- `ddev-setup-settings/`: DDEV 환경 설정 관련 파일들

## 빠른 시작

이 저장소에 포함된 설치 스크립트를 사용하여 새로운 DDEV 프로젝트를 쉽게 생성할 수 있습니다.

### 설치 스크립트 사용법

```bash
# WordPress 프로젝트 생성
./install.sh --type wordpress --name my-wordpress-site

# Laravel 프로젝트 생성
./install.sh --type laravel --name my-laravel-site

# 특정 경로에 프로젝트 생성
./install.sh --type wordpress --name custom-wp --directory /path/to/projects
```

### 설치 스크립트 옵션

- `-t, --type`: 프로젝트 유형 (wordpress 또는 laravel) [필수]
- `-n, --name`: 프로젝트 이름 [필수]
- `-d, --directory`: 프로젝트 설치 디렉토리 (기본값: 현재 디렉토리 내의 프로젝트 이름)
- `-h, --help`: 도움말 표시

## 테스트

제공된 테스트 스크립트를 사용하여 설치 스크립트가 올바르게 작동하는지 확인할 수 있습니다.

### 테스트 스크립트 사용법

```bash
# 테스트 모드 실행 (실제 DDEV 프로젝트 생성 없음)
./test-install.sh

# 실제 모드 실행 (실제 DDEV 프로젝트 생성)
./test-install.sh --no-dry-run

# 테스트 후 디렉토리 유지
./test-install.sh --skip-cleanup
```

### 테스트 스크립트 옵션

- `--no-dry-run`: 실제로 DDEV 프로젝트를 생성합니다 (기본값: dry-run 모드)
- `--skip-cleanup`: 테스트 후 디렉토리를 정리하지 않습니다 (기본값: 정리함)
- `-h, --help`: 도움말 표시

## 사용 방법

자세한 사용 방법은 [HOW_TO_USE_DDEV.md](HOW_TO_USE_DDEV.md) 파일을 참조하세요. 