# DDEV 프로젝트

이 저장소는 DDEV를 사용한 개발 환경 설정을 위한 프로젝트입니다.

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