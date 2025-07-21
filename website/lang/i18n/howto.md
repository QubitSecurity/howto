PHP 기반 시스템에서 Hugo의 `i18n` 스타일을 차용해 다국어 지원을 구현하려면 다음과 같은 접근을 추천합니다:

---

## ✅ 1. 다국어 번역 파일 구조 (`i18n/en.php`, `i18n/ko.php` 등)

먼저 Hugo의 TOML 파일 구조를 PHP 배열로 변환합니다.

**📁 `i18n/en.php`**

```php
<?php
return [
    'check_disk_usage' => 'Check Disk Usage',
    'test_insert_table' => 'Test Insert Table',
    'ansible_mysql_insert' => 'Ansible MySQL Insert',
    'remote_mysql_backup' => 'Remote MySQL Backup',
    'ansible_mysql_backup' => 'Ansible MySQL Backup',
    'check_ssl_cert' => 'Check SSL Certificate',
    'ocsp_cert_check' => 'OCSP Certificate Check',
    'ansible_mysql_integrity_check' => 'Ansible MySQL Integrity Check',
    'ansible_jar_integrity_check' => 'Ansible JAR Integrity Check',
];
```

**📁 `i18n/ko.php`**

```php
<?php
return [
    'check_disk_usage' => '디스크 사용량 확인',
    'test_insert_table' => '테스트 테이블 삽입',
    'ansible_mysql_insert' => 'Ansible MySQL 삽입',
    'remote_mysql_backup' => '원격 MySQL 백업',
    'ansible_mysql_backup' => 'Ansible MySQL 백업',
    'check_ssl_cert' => 'SSL 인증서 확인',
    'ocsp_cert_check' => 'OCSP 인증서 확인',
    'ansible_mysql_integrity_check' => 'MySQL 무결성 검사',
    'ansible_jar_integrity_check' => 'JAR 무결성 검사',
];
```

---

## ✅ 2. 언어 설정 및 번역 함수

**📁 `lang.php`**

```php
<?php
function load_i18n($lang = 'en') {
    $file = __DIR__ . "/i18n/{$lang}.php";
    if (file_exists($file)) {
        return include $file;
    }
    return include __DIR__ . "/i18n/en.php"; // fallback
}

function __t($key) {
    global $i18n;
    return $i18n[$key] ?? $key;
}
```

---

## ✅ 3. `index.php` 또는 `index.html`에 적용

`index.php`로 확장한 뒤 다음처럼 적용합니다:

```php
<?php
$lang = $_GET['lang'] ?? 'en';
require_once 'lang.php';
$i18n = load_i18n($lang);
?>
<!DOCTYPE html>
<html lang="<?= htmlspecialchars($lang) ?>">
<head>
  <meta charset="UTF-8">
  <title>Monitoring Dashboard</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
  <link rel="stylesheet" href="./css/style.css">
</head>
<body>
  <div class="container">
    <h1 class="mb-4">🛠️ SysWatch: Monitoring Tools</h1>

    <div class="form-section">
      <h2><?= __t('check_disk_usage') ?></h2>
      ...
    </div>

    <div class="form-section">
      <h2><?= __t('test_insert_table') ?></h2>
      ...
    </div>

    <!-- 나머지 섹션 동일한 방식으로 -->
  </div>
</body>
</html>
```

---

## ✅ 4. 언어 선택 방식

* 기본은 URL 파라미터: `?lang=ko`
* 또는 `Accept-Language` HTTP 헤더를 통해 자동 감지 로직 추가도 가능

---

## ✅ 요약

| 항목           | 방식                                              |
| ------------ | ----------------------------------------------- |
| 번역 데이터 저장    | `i18n/en.php`, `i18n/ko.php` 등 PHP 배열 형태        |
| 번역 로딩 및 접근   | `load_i18n()`, `__t()` 함수로 처리                   |
| 템플릿 내 다국어 출력 | `<h2><?= __t('check_disk_usage') ?></h2>` 방식 사용 |
| 언어 선택        | URL 파라미터 또는 자동 감지                               |

---

필요시 `.po/.mo` 방식 또는 JSON + JS 렌더링 방식으로 확장도 가능하지만, 현재 구조에는 PHP 기반 배열 방식이 가장 단순하고 Hugo 스타일과 유사합니다.
