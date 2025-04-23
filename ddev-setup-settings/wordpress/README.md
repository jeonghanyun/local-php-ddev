# DDEV를 활용한 WordPress 개발 환경

이 가이드는 DDEV를 사용하여 WordPress 로컬 개발 환경을 설정하는 방법을 설명합니다.

## 목차

- [프로젝트 설정](#프로젝트-설정)
- [WordPress 설치](#wordpress-설치)
- [개발 작업](#개발-작업)
- [유용한 팁](#유용한-팁)

## 프로젝트 설정

### 1. 프로젝트 디렉토리 생성 및 이동

```bash
mkdir wordpress-site
cd wordpress-site
```

### 2. DDEV 프로젝트 설정

```bash
ddev config --project-type=wordpress --project-name=wordpress-site --docroot=.
```

### 3. WordPress 자동 다운로드를 위한 훅 설정

`.ddev/config.yaml` 파일을 열고 다음 내용을 추가합니다:

```yaml
hooks:
  post-start:
    - exec: '[ ! -f wp-load.php ] && (curl -O https://wordpress.org/latest.tar.gz && tar -xzf latest.tar.gz --strip-components=1 && rm latest.tar.gz) || echo "WordPress core files already present, skipping download."'
```

이 설정은 DDEV 프로젝트가 시작될 때 WordPress 코어 파일이 없으면 자동으로 다운로드합니다.

## WordPress 설치

### 1. DDEV 프로젝트 시작

```bash
ddev start
```

### 2. 브라우저에서 WordPress 설치 마법사 실행

브라우저에서 다음 URL 중 하나로 접속하여 WordPress 설치를 완료합니다:
- https://wordpress-site.ddev.site
- http://127.0.0.1:포트번호 (포트 번호는 `ddev describe` 명령으로 확인 가능)

설치 과정에서 필요한 정보:
- 사이트 제목: 원하는 사이트 이름
- 사용자 이름: 관리자 계정 이름
- 비밀번호: 강력한 비밀번호 선택
- 이메일: 관리자 이메일 주소

데이터베이스 정보는 DDEV가 자동으로 구성하므로 입력할 필요가 없습니다.

## 개발 작업

### 테마 개발

WordPress 테마는 `wp-content/themes/` 디렉토리에 생성합니다:

```bash
cd wp-content/themes/
mkdir my-custom-theme
cd my-custom-theme
# 테마 파일 생성
```

### 플러그인 개발

WordPress 플러그인은 `wp-content/plugins/` 디렉토리에 생성합니다:

```bash
cd wp-content/plugins/
mkdir my-custom-plugin
cd my-custom-plugin
# 플러그인 파일 생성
```

### WP-CLI 사용

DDEV는 WordPress 명령줄 인터페이스(WP-CLI)를 내장하고 있습니다:

```bash
ddev wp plugin list
ddev wp theme activate my-custom-theme
ddev wp user create test test@example.com --role=author
```

## 유용한 팁

### 데이터베이스 정보

WordPress 설치 및 개발 중 필요할 수 있는 데이터베이스 접속 정보:

- **데이터베이스 이름**: `db`
- **사용자 이름**: `db` 또는 `root`
- **비밀번호**: `db` 또는 `root`
- **호스트**: `db`
- **포트**: `3306`

### 데이터베이스 관리

```bash
# phpMyAdmin 열기
ddev launch -p

# 데이터베이스 내보내기
ddev export-db --file=wordpress-backup.sql.gz

# 데이터베이스 가져오기
ddev import-db --file=wordpress-backup.sql.gz
```

### 파일 접근 및 권한

WordPress 파일 시스템에 접근하려면:

```bash
# DDEV 컨테이너에 SSH 접속
ddev ssh

# 파일 권한 수정 (필요한 경우)
chmod -R 755 wp-content/
```

### 웹사이트 백업

전체 WordPress 사이트를 백업하려면:

```bash
# 파일 시스템 백업
ddev export-db --file=~/backups/wordpress-db.sql.gz

# 수동으로 wp-content 디렉토리 복사
cp -r wp-content ~/backups/wp-content-backup
```

### 추가 리소스

- [WordPress 개발자 문서](https://developer.wordpress.org/)
- [DDEV WordPress 문서](https://ddev.readthedocs.io/en/stable/users/quickstart/#wordpress) 