# DDEV를 활용한 Laravel 개발 환경

이 가이드는 DDEV를 사용하여 Laravel 로컬 개발 환경을 설정하는 방법을 설명합니다.

## 목차

- [프로젝트 설정](#프로젝트-설정)
- [Laravel 설치](#laravel-설치)
- [개발 작업](#개발-작업)
- [유용한 팁](#유용한-팁)

## 프로젝트 설정

### 1. 프로젝트 디렉토리 생성 및 이동

```bash
mkdir laravel-site
cd laravel-site
```

### 2. DDEV 프로젝트 설정

```bash
ddev config --project-type=laravel --project-name=laravel-site --docroot=public
```

Laravel 프로젝트는 document root가 `public` 디렉토리이므로 `--docroot=public`으로 설정합니다.

### 3. Laravel 자동 설치를 위한 훅 설정

`.ddev/config.yaml` 파일을 열고 다음 내용을 추가합니다:

```yaml
hooks:
  post-start:
    - exec: "if [ ! -f artisan ]; then composer create-project --prefer-dist laravel/laravel:^11.0 . && chmod -R 775 storage bootstrap/cache; fi"
```

이 설정은 DDEV 프로젝트가 시작될 때 Laravel 프레임워크가 없으면 자동으로 설치합니다.

## Laravel 설치

### 1. DDEV 프로젝트 시작

```bash
ddev start
```

이 명령은 Laravel 프로젝트를 자동으로 설치합니다. 첫 실행 시 몇 분 정도 소요될 수 있습니다.

### 2. 설치 확인

브라우저에서 다음 URL 중 하나로 접속하여 Laravel 설치를 확인합니다:
- https://laravel-site.ddev.site
- http://127.0.0.1:포트번호 (포트 번호는 `ddev describe` 명령으로 확인 가능)

기본 Laravel 환영 페이지가 표시되면 설치가 성공적으로 완료된 것입니다.

## 개발 작업

### 아티즌 명령어 실행

Laravel의 Artisan 명령은 DDEV 내에서 실행할 수 있습니다:

```bash
# 컨트롤러 생성
ddev exec php artisan make:controller UserController

# 마이그레이션 실행
ddev exec php artisan migrate

# 시드 실행
ddev exec php artisan db:seed

# 모든 아티즌 명령 확인
ddev exec php artisan list
```

### NPM 명령어 실행

Laravel Mix(또는 Vite)를 사용한 프론트엔드 개발:

```bash
# NPM 패키지 설치
ddev exec npm install

# 개발 모드에서 실행
ddev exec npm run dev

# 프로덕션용 빌드
ddev exec npm run build
```

### 라우트 정의

`routes/web.php` 파일에서 웹 라우트를 정의합니다:

```php
Route::get('/hello', function () {
    return 'Hello, World!';
});
```

## 유용한 팁

### 데이터베이스 정보

Laravel `.env` 파일에서 사용할 데이터베이스 접속 정보:

```
DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=db
DB_USERNAME=db
DB_PASSWORD=db
```

DDEV는 이러한 정보를 자동으로 구성하며, `.env` 파일이 자동으로 생성됩니다.

### 데이터베이스 관리

```bash
# phpMyAdmin 열기
ddev launch -p

# 데이터베이스 내보내기
ddev export-db --file=laravel-backup.sql.gz

# 데이터베이스 가져오기
ddev import-db --file=laravel-backup.sql.gz
```

### Composer 종속성 관리

```bash
# Composer 패키지 설치
ddev exec composer install

# 새 패키지 추가
ddev exec composer require package/name

# 개발용 패키지 추가
ddev exec composer require --dev package/name
```

### 캐시 및 설정 관리

```bash
# 설정 캐시 생성
ddev exec php artisan config:cache

# 캐시 모두 지우기
ddev exec php artisan cache:clear
ddev exec php artisan config:clear
ddev exec php artisan route:clear
ddev exec php artisan view:clear
```

### Laravel Queue 사용

```bash
# 대기열 워커 실행
ddev exec php artisan queue:work
```

### Redis 연결

DDEV에 Redis 추가:

`.ddev/config.yaml` 파일을 수정하여 Redis 서비스를 추가합니다:

```yaml
webserver_type: nginx-fpm
database_type: mysql
router_http_port: "80"
router_https_port: "443"
additional_services:
  - name: redis
    type: redis:6
```

그런 다음 `.env` 파일에서 Redis 연결 정보를 설정합니다:

```
REDIS_HOST=redis
REDIS_PASSWORD=null
REDIS_PORT=6379
```

### 추가 리소스

- [Laravel 공식 문서](https://laravel.com/docs)
- [DDEV Laravel 문서](https://ddev.readthedocs.io/en/stable/users/quickstart/#laravel) 