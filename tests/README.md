# DDEV 테스트 모음

이 디렉토리에는 DDEV 프로젝트와 관련된 모든 테스트 파일이 포함되어 있습니다.

## 디렉토리 구조

- `ddev-setup-settings/`: DDEV 설정 관련 테스트 스크립트
  - `real-world-test.sh`: 실제 환경에서의 테스트를 위한 스크립트
  - `test-catalog-scripts.sh`: 카탈로그 스크립트 테스트
  - `test-registry-update.sh`: 레지스트리 업데이트 테스트

- `registry-test/`: 레지스트리 관련 테스트 파일
  - `ddev-project-registry.json`: 테스트용 프로젝트 레지스트리 파일

- `simple-test/`: 단순 테스트를 위한 카탈로그 파일
  - `laravel-catalog.json`: Laravel 테스트 카탈로그
  - `wp-catalog.json`: WordPress 테스트 카탈로그

- `real-world-test/`: 실제 환경 테스트를 위한 카탈로그 파일
  - `laravel-catalog.json`: Laravel 실제 환경 테스트 카탈로그
  - `wp-catalog.json`: WordPress 실제 환경 테스트 카탈로그

- `test-projects/`: 테스트 프로젝트 파일
  - `laravel-catalog-test.json`: Laravel 테스트 카탈로그 파일
  - `laravel-catalog-test.json.before`: Laravel 테스트 카탈로그 백업 파일
  - `wp-catalog-test.json`: WordPress 테스트 카탈로그 파일
  - `wp-catalog-test.json.before`: WordPress 테스트 카탈로그 백업 파일

- `test-install.sh`: 설치 테스트 스크립트
- `test-install-new.sh`: 새로운 설치 테스트 스크립트

## 테스트 실행 방법

기본 테스트 실행:
```bash
./tests/test-install.sh
```

새 테스트 실행:
```bash
./tests/test-install-new.sh
```

설정 테스트 실행:
```bash
./tests/ddev-setup-settings/real-world-test.sh
./tests/ddev-setup-settings/test-catalog-scripts.sh
./tests/ddev-setup-settings/test-registry-update.sh
``` 