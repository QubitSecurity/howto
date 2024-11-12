# 정적 사이트 생성기(Static Site Generator, SSG)

마크다운 문서를 GitHub에서 가져와 HTML로 변환하여 가볍게 보여주는 웹 서버를 구축하려면 다음과 같이 진행하시면 됩니다:

---

**1. Nginx 설정**

- **Nginx 설치 및 설정**
  ```bash
  sudo apt-get update
  sudo apt-get install nginx
  ```
- **서버 블록 설정**  
  `/etc/nginx/sites-available/default` 파일을 편집하여 문서를 제공할 디렉토리를 설정합니다.
  ```nginx
  server {
      listen 80 default_server;
      listen [::]:80 default_server;

      root /var/www/markdown_site/html;
      index index.html;

      server_name _;

      location / {
          try_files $uri $uri/ =404;
      }
  }
  ```
- **Nginx 재시작**
  ```bash
  sudo systemctl restart nginx
  ```

---

**2. GitHub에서 문서 가져오기**

- **디렉토리 생성 및 저장소 클론**
  ```bash
  sudo mkdir -p /var/www/markdown_site/markdown
  sudo chown -R $USER:$USER /var/www/markdown_site
  git clone https://github.com/yourusername/yourrepo.git /var/www/markdown_site/markdown
  ```
- **업데이트 스크립트 작성**
  `/usr/local/bin/update_markdown.sh`에 다음 내용을 작성합니다.
  ```bash
  #!/bin/bash
  cd /var/www/markdown_site/markdown
  git pull origin main
  ```
  스크립트에 실행 권한을 부여합니다.
  ```bash
  sudo chmod +x /usr/local/bin/update_markdown.sh
  ```
- **크론 잡 설정**
  ```bash
  crontab -e
  ```
  다음 라인을 추가하여 매시간마다 업데이트되도록 합니다.
  ```
  0 * * * * /usr/local/bin/update_markdown.sh
  ```

---

**3. 마크다운을 HTML로 변환**

- **Pandoc 설치**
  ```bash
  sudo apt-get install pandoc
  ```
- **변환 스크립트 작성**
  `/usr/local/bin/convert_markdown.sh`에 다음 내용을 작성합니다.
  ```bash
  #!/bin/bash
  INPUT_DIR="/var/www/markdown_site/markdown"
  OUTPUT_DIR="/var/www/markdown_site/html"

  mkdir -p $OUTPUT_DIR

  find $INPUT_DIR -name "*.md" | while read file; do
      relative_path="${file#$INPUT_DIR/}"
      output_file="$OUTPUT_DIR/${relative_path%.md}.html"
      output_dir=$(dirname "$output_file")
      mkdir -p "$output_dir"
      pandoc "$file" -o "$output_file"
  done
  ```
  스크립트에 실행 권한을 부여합니다.
  ```bash
  sudo chmod +x /usr/local/bin/convert_markdown.sh
  ```
- **크론 잡에 변환 스크립트 추가**
  ```bash
  crontab -e
  ```
  업데이트 스크립트 이후에 변환 스크립트를 추가합니다.
  ```
  0 * * * * /usr/local/bin/update_markdown.sh && /usr/local/bin/convert_markdown.sh
  ```

---

**4. Nginx에서 HTML 파일 제공**

- **Nginx 설정 확인**
  앞서 설정한 대로 Nginx의 `root` 디렉토리가 `/var/www/markdown_site/html`로 설정되어 있는지 확인합니다.
- **Nginx 재시작**
  ```bash
  sudo systemctl restart nginx
  ```

---

**5. 추가 설정 (선택 사항)**

- **스타일 적용**
  - `/var/www/markdown_site/html` 디렉토리에 CSS 파일을 추가하고, 변환 시 해당 CSS를 포함하도록 Pandoc 옵션을 수정합니다.
  - 변환 스크립트에서 Pandoc 명령을 다음과 같이 수정합니다.
    ```bash
    pandoc "$file" -c "/css/style.css" -o "$output_file"
    ```
- **파일 변경 감지하여 자동 변환**
  - `inotifywait`을 사용하여 파일 변경을 감지하고 실시간으로 변환할 수 있습니다.
  - 그러나 시스템 리소스를 고려하여 크론 잡으로 일정 시간마다 실행하는 것을 권장합니다.

---

이렇게 설정하시면 복잡한 환경 없이도 GitHub의 마크다운 문서를 자동으로 HTML로 변환하고, Nginx를 통해 가볍게 제공할 수 있습니다.
