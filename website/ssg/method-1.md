알겠습니다! 제가 제안하신 요구사항에 맞춰 문서를 조금 더 다듬고 명확하게 정리하겠습니다.

---

### **GitHub 데이터 기반 SSG 시스템 구축**

이 문서에서는 기존의 SSG 시스템을 확장하여 **GitHub에서 데이터를 가져오고**, **화면에 출력**하며, **목록 관리 및 페이징 기능**을 제공하는 방법을 설명합니다.

---

### **목표**

- **데이터 가져오기**: GitHub 저장소에서 마크다운 파일을 가져옵니다.
- **화면 출력**: 마크다운 파일을 HTML로 변환하여 사용자에게 제공합니다.
- **목록 관리**: 게시물 목록을 생성하고 표시합니다.
- **페이징 기능**: 게시물을 페이지별로 나누어 사용자 경험을 개선합니다.
- **언어 선택 및 폰트 적용**: 언어 선택 기능과 폰트 설정을 유지합니다.

---

### **구성 요소 및 구조**

```mermaid
graph LR
    subgraph 서버
        D[크론 잡]
        B[업데이트 스크립트<br>/usr/local/bin/update_markdown.sh]
        C[변환 스크립트<br>/usr/local/bin/convert_markdown.sh]
        E[마크다운 파일<br>/var/www/markdown_site/markdown]
        F[HTML 파일<br>/var/www/markdown_site/html]
        I[인덱스 생성 스크립트<br>/usr/local/bin/generate_index.sh]
        T[Pandoc 템플릿<br>/var/www/markdown_site/pandoc_template.html]
        S[CSS 파일<br>/var/www/markdown_site/html/css/style.css]
        G[Nginx 서버]
    end
    A[GitHub 저장소] -->|git pull| B
    D -->|정기 실행| B
    B -->|업데이트| E
    B -->|업데이트 후 실행| C
    C -->|읽기| E
    C -->|사용| T
    C -->|사용| S
    C -->|생성| F
    C -->|변환 후 실행| I
    I -->|인덱스 페이지 생성| F
    G -->|제공| F
    H[사용자] -->|HTTP 요청| G
    H -->|언어 선택 및 페이징| G
```

---

### **1. 업데이트 스크립트 (`update_markdown.sh`)**

GitHub 저장소에서 최신 마크다운 파일을 가져오는 부분은 기존과 동일합니다.

```bash
#!/bin/bash
cd /var/www/markdown_site/markdown
git pull origin main
```

- **설명**: GitHub 저장소에서 최신 마크다운 파일을 가져와 로컬 디렉토리에 업데이트합니다.

---

### **2. 변환 스크립트 (`convert_markdown.sh`)**

마크다운 파일을 HTML로 변환하는 스크립트로, 메타데이터를 추출하고 변환 후 인덱스 생성 스크립트를 실행합니다.

```bash
#!/bin/bash
INPUT_DIR="/var/www/markdown_site/markdown"
OUTPUT_DIR="/var/www/markdown_site/html"
CSS_FILE="/css/style.css"
TEMPLATE_FILE="/var/www/markdown_site/pandoc_template.html"
POSTS_DATA="/var/www/markdown_site/posts_data.txt"

# 기존 posts_data.txt 파일 삭제
rm -f "$POSTS_DATA"

mkdir -p "$OUTPUT_DIR"

find "$INPUT_DIR" -name "*.md" | while read -r file; do
    relative_path="${file#$INPUT_DIR/}"
    filename=$(basename "$file")
    filename_without_ext="${filename%.md}"
    lang_code="${filename_without_ext##*.}" # 파일명에서 언어 코드를 추출 (예: post-title.en.md)

    # 언어 코드를 추출할 수 없는 경우 기본 언어를 설정
    if [[ "$lang_code" != "en" && "$lang_code" != "ko" && "$lang_code" != "ja" ]]; then
        lang_code="en"
    fi

    output_file="$OUTPUT_DIR/${relative_path%.md}.html"
    output_dir=$(dirname "$output_file")
    mkdir -p "$output_dir"

    # 메타데이터 추출 (제목 및 날짜)
    title=$(grep '^# ' "$file" | head -n1 | sed 's/# //')
    date=$(grep '^Date: ' "$file" | head -n1 | sed 's/Date: //')

    # posts_data.txt에 게시물 정보 추가
    echo -e "${filename_without_ext}\t${title}\t${date}\t${lang_code}" >> "$POSTS_DATA"

    # Pandoc을 사용하여 HTML로 변환
    pandoc "$file" \
        -o "$output_file" \
        --standalone \
        --template="$TEMPLATE_FILE" \
        --metadata=lang:"$lang_code" \
        -c "$CSS_FILE" \
        --metadata title="$title"
done

# 변환 후 인덱스 생성 스크립트 실행
/usr/local/bin/generate_index.sh
```

- **설명**:
  - 각 마크다운 파일에서 제목과 날짜 메타데이터를 추출하여 `posts_data.txt` 파일에 저장합니다.
  - 변환 후 인덱스 생성 스크립트(`generate_index.sh`)를 실행하여 인덱스 페이지를 만듭니다.

---

### **3. 인덱스 생성 스크립트 (`generate_index.sh`)**

`posts_data.txt`를 기반으로 인덱스 페이지를 생성하고, 페이징 기능을 구현합니다.

```bash
#!/bin/bash
OUTPUT_DIR="/var/www/markdown_site/html"
POSTS_DATA="/var/www/markdown_site/posts_data.txt"
TEMPLATE_FILE="/var/www/markdown_site/index_template.html"
POSTS_PER_PAGE=5

# 언어 목록
LANGUAGES=("en" "ko" "ja")

for lang in "${LANGUAGES[@]}"; do
    # 해당 언어의 게시물 필터링
    grep -P "\t${lang}$" "$POSTS_DATA" | sort -k3 -r > "/tmp/posts_${lang}.txt"
    total_posts=$(cat "/tmp/posts_${lang}.txt" | wc -l)
    total_pages=$(( (total_posts + POSTS_PER_PAGE - 1) / POSTS_PER_PAGE ))

    for ((page=1; page<=total_pages; page++)); do
        start=$(( (page - 1) * POSTS_PER_PAGE + 1 ))
        end=$(( start + POSTS_PER_PAGE - 1 ))
        sed -n "${start},${end}p" "/tmp/posts_${lang}.txt" > "/tmp/posts_page_${lang}_${page}.txt"

        # 인덱스 페이지 생성
        output_file="${OUTPUT_DIR}/index${page}.${lang}.html"

        # 게시물 목록을 HTML로 변환
        posts_html=""
        while IFS=$'\t' read -r filename title date lang_code; do
            posts_html+="<li><a href=\"${filename}.${lang_code}.html\">${title}</a> - ${date}</li>"
        done < "/tmp/posts_page_${lang}_${page}.txt"

        # 페이징 네비게이션 생성
        pagination=""
        for ((i=1; i<=total_pages; i++)); do
            if [ $i -eq $page ]; then
                pagination+="<strong>${i}</strong> "
            else
                pagination+="<a href=\"index${i}.${lang}.html\">${i}</a> "
            fi
        done

        # 템플릿을 사용하여 인덱스 페이지 생성
        sed \
            -e "s|{{lang}}|${lang}|g" \
            -e "s|{{posts}}|${posts_html}|g" \
            -e "s|{{pagination}}|${pagination}|g" \
            "$TEMPLATE_FILE" > "$output_file"
    done
done
```

- **설명**:
  - 각 언어별로 게시물 목록을 생성하고, 페이지당 게시물 수를 설정하여 페이징을 구현합니다.
  - 템플릿 파일(`index_template.html`)을 사용하여 인덱스 페이지를 생성합니다.

---

### **4. 인덱스 페이지 템플릿 (`index_template.html`)**

인덱스 페이지의 HTML 구조를 정의합니다.

```html
<!DOCTYPE html>
<html lang="{{lang}}">
<head>
    <meta charset="UTF-8">
    <title>Your Site Title - Index</title>
    <link rel="stylesheet" href="/css/style.css">
</head>
<body>

<header>
    <div class="language-selector">
        <ul>
            <li><a href="index1.en.html">English</a></li>
            <li><a href="index1.ko.html">한국어</a></li>
            <li><a href="index1.ja.html">日本語</a></li>
        </ul>
    </div>
</header>

<div class="content">
    <h1>Your Site Title</h1>
    <ul>
        {{posts}}
    </ul>
    <div class="pagination">
        {{pagination}}
    </div>
</div>

</body>
</html>
```

- **설명**: `{{lang}}`, `{{posts}}`, `{{pagination}}`은 인덱스 생성 스크립트에서 실제 값으로 대체됩니다.

---

### **

5. Pandoc 템플릿 (`pandoc_template.html`) 수정**

각 게시물 페이지의 HTML 템플릿입니다.

```html
<!DOCTYPE html>
<html lang="$lang$">
<head>
    <meta charset="UTF-8">
    <title>$title$</title>
    <link rel="stylesheet" href="$css$">
</head>
<body>

<header>
    <div class="language-selector">
        <ul>
            <li><a href="index1.en.html">English</a></li>
            <li><a href="index1.ko.html">한국어</a></li>
            <li><a href="index1.ja.html">日本語</a></li>
        </ul>
    </div>
</header>

<div class="content">
    $body$
</div>

</body>
</html>
```

- **설명**: 언어 선택 메뉴와 콘텐츠를 포함한 게시물 페이지 템플릿입니다.

---

### **6. CSS 파일 (`style.css`)**

목록과 페이징 스타일을 추가한 CSS 파일입니다.

```css
/* /css/style.css */

/* 기존 스타일 생략 */

/* 게시물 목록 스타일 */
.content ul {
    list-style-type: none;
    padding: 0;
}

.content ul li {
    margin-bottom: 10px;
}

/* 페이징 네비게이션 스타일 */
.pagination {
    margin-top: 20px;
}

.pagination a {
    margin: 0 5px;
    text-decoration: none;
    color: #007bff;
}

.pagination a:hover {
    text-decoration: underline;
}

.pagination strong {
    margin: 0 5px;
    font-weight: bold;
}
```

---

### **전체 동작 흐름**

1. **크론 잡 실행**: 정기적으로 `update_markdown.sh`를 실행하여 GitHub 데이터를 가져옵니다.
2. **변환 스크립트**: `convert_markdown.sh`를 실행하여 마크다운 파일을 HTML로 변환하고, 메타데이터를 수집하여 인덱스 생성 스크립트를 실행합니다.
3. **인덱스 페이지 생성**: `generate_index.sh`를 통해 언어별 인덱스 페이지와 페이징을 구현합니다.
4. **Nginx를 통한 제공**: Nginx 서버를 통해 최신 HTML 파일을 사용자에게 제공합니다.

---

이 구조로, GitHub 데이터를 기반으로 한 다국어 지원 SSG 시스템이 완성됩니다. 추가 기능 구현이나 질문이 있으시면 언제든지 문의해주세요!
