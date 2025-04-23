# DDEV 설치 및 개발 환경 구성 가이드

이 저장소는 DDEV를 사용하여 다양한 PHP 프레임워크의 로컬 개발 환경을 설정하는 방법을 제공합니다.

## 목차

- [DDEV 소개](#ddev-소개)
- [DDEV 설치 방법](#ddev-설치-방법)
- [프로젝트 목록](#프로젝트-목록)
- [공통 명령어](#공통-명령어)

## DDEV 소개

DDEV는 PHP 웹 애플리케이션을 위한 오픈소스 로컬 개발 환경입니다. Docker 컨테이너를 기반으로 하며, WordPress, Laravel, Drupal, TYPO3 등 다양한 PHP 프레임워크와 CMS를 쉽게 설정할 수 있습니다.

주요 장점:
- 간편한 설치 및 구성
- 다양한 PHP 버전 지원
- 프로젝트별 구성 가능
- 각 프로젝트에 대해 격리된 환경 제공
- 팀 간 개발 환경 일관성 유지

## DDEV 설치 방법

### 사전 요구사항

- [Docker](https://www.docker.com/products/docker-desktop/) 설치 필요

### macOS에 DDEV 설치하기

Homebrew를 사용하여 DDEV를 설치합니다:

```bash
brew install ddev/ddev/ddev
```

### Windows에 DDEV 설치하기

Chocolatey를 사용하여 DDEV를 설치합니다:

```bash
choco install ddev
```

또는 PowerShell 스크립트 사용:

```powershell
curl -LO https://raw.githubusercontent.com/ddev/ddev/master/scripts/install_ddev.ps1
.\install_ddev.ps1
```

### Linux에 DDEV 설치하기

```bash
curl -LO https://raw.githubusercontent.com/ddev/ddev/master/scripts/install_ddev.sh
bash install_ddev.sh
```

### 설치 확인

```bash
ddev --version
```

## 프로젝트 목록

이 저장소에는 다음 프로젝트가 포함되어 있습니다:

- [WordPress 개발 환경](wordpress/README.md) - DDEV를 사용한 WordPress 개발 환경 설정
- [Laravel 개발 환경](laravel/README.md) - DDEV를 사용한 Laravel 개발 환경 설정

## 공통 명령어

모든 DDEV 프로젝트에서 사용할 수 있는 주요 명령어:

```bash
# 새 프로젝트 구성
ddev config

# 프로젝트 시작
ddev start

# 프로젝트 중지
ddev stop

# 모든 프로젝트 중지
ddev poweroff

# 프로젝트 상태 확인
ddev status

# 프로젝트 정보 확인
ddev describe

# 프로젝트 컨테이너에 SSH 접속
ddev ssh

# 데이터베이스 관리 도구 열기
ddev launch -p

# 프로젝트 삭제 (컨테이너와 볼륨 제거)
ddev delete
```

## 더 많은 정보

- [DDEV 공식 문서](https://ddev.readthedocs.io/)
- [DDEV GitHub 저장소](https://github.com/ddev/ddev)
- [DDEV 포럼](https://discord.gg/hCZFfAMc5k) 