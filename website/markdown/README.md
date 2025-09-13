# 📄 Markdown Viewer 정리

이 문서는 **Markdown(마크다운)** 형식으로 작성된 문서를  
웹 브라우저에서 **HTML 문서처럼 보기 쉽게** 보여주는 방법을 정리한 것입니다.  

즉, 마크다운 파일을 그대로 저장하고 관리하면서도,  
사용자는 웹 브라우저에서 깔끔하게 읽을 수 있도록 만드는 방법입니다.  
크게 두 가지 방식이 있습니다.  

---

## 1) HTML만 서비스하는 정적 웹 서비스에서 지원하기

가장 간단한 방법은 **정적 웹 서버(Nginx, Apache 등)** 에 샘플 `index.html` 파일만 두고 사용하는 방식입니다.  

- 브라우저 주소창에서 `?doc=...` 값을 주면, 해당 마크다운 문서를 불러와서 HTML로 변환해 보여줍니다.
- 서버에는 별도의 프로그램을 설치할 필요가 없습니다.  
- 즉, **HTML과 마크다운 파일만 있으면 바로 동작**합니다.  

📌 예시: [PLURA Philosophy](https://w.plura.io/index.html?doc=/philosophy/ko/README.md)

📌 동작 구조  
1. `index.html`이 `doc` 파라미터(파일 경로)를 읽습니다.  
2. JavaScript가 `fetch`로 마크다운 파일을 가져옵니다.  
3. `markdown-it`, `highlight.js`, `KaTeX`, `Mermaid` 같은 라이브러리가  
   내용을 HTML로 바꿔 브라우저에 표시합니다.  

4. 예제 코드는 [`index.html`](./html/index.html) 문서를 참고하세요.

5. GitHub 등 **외부 URL**을 `doc` 파라미터로 직접 불러오는 확장 버전도 있습니다.  
   - **Raw 주소만 지원**합니다. (`github.com/.../blob/...` → 자동 변환 없음)  
   - GitHub 파일 페이지에서 **Raw** 버튼을 눌러 나온 주소(`https://raw.githubusercontent.com/...`)를 사용하세요.  
   - `url-index.html`은 렌더 전에 다음을 **자동 처리**합니다.  
     - 문서 상단의 **YAML 프론트매터**(`--- ... ---`) 제거  
     - `<!--more-->`, `<!-- more -->`, `<!–more–>`(엔대시/엠대시 변형) 마커 제거

   📌 예시: [PLURA Philosophy (GitHub Raw에서 직접 불러오기)](https://w.plura.io/url-index.html?doc=https://raw.githubusercontent.com/qubitsec/plura/main/philosophy/ko/README.md)  
   예제 코드는 [`url-index.html`](./html/url-index.html) 문서를 참고하세요.

6. **md 파일 문서를 pdf로 저장하는 확장 버전**

   마크다운을 화면에서 렌더한 뒤, **라이트/다크 테마**와 **머리말·꼬리말(제목·날짜·페이지번호)**을 포함하여 **PDF로 저장**합니다.  
   서버 측 프로그램 없이 **정적 HTML 한 파일(`html2pdf.html`)**만 배포하면 됩니다.

   - **수동 다운로드만** 지원: 자동 실행(`pdf=1`)은 제거, **[PDF 다운로드] 버튼**으로만 생성  
   - **테마**: `pdftheme=light | dark | auto` (기본 `auto`=라이트 PDF)  
   - **용지/여백**: `pagesize=a4 | letter`, `margin=narrow | normal | wide`  
   - **페이지 분할**: 마크다운 본문에 `<!--pagebreak-->` 마커를 넣으면 해당 지점에서 강제 쪽 나눔  
   - **UI 안전**: 화면은 끝까지 그대로(다크 유지), PDF는 **오프스크린 샌드박스 복제본**에서 생성  
   - **외부 Raw URL 지원**: GitHub **Raw** 주소를 `doc=`로 지정하면 바로 변환

   > 파일 배치 예시: `/html/html2pdf.html`

   **사용법**
   1) 서버에 `html2pdf.html` 업로드  
   2) 브라우저에서 아래 형식으로 접속 → 화면 상단 **[PDF 다운로드]** 클릭
   ```text
   https://<your-host>/html2pdf.html?doc=<문서URL>[&옵션들...]
   ```

**옵션 요약**

| 파라미터       | 값                            | 기본값      | 설명                                                                                 |
| ---------- | ---------------------------- | -------- | ---------------------------------------------------------------------------------- |
| `doc`      | 파일 경로 또는 **Raw URL**         | (필수)     | 마크다운 문서. `github.com/.../blob/...` **미지원**, `raw.githubusercontent.com/...` **지원** |
| `pdftheme` | `light` · `dark` · `auto`    | `auto`   | PDF 테마(화면은 기본 다크, `light`일 때 화면도 라이트 미리보기)                                         |
| `pagesize` | `a4` · `letter`              | `a4`     | 용지 크기                                                                              |
| `margin`   | `narrow` · `normal` · `wide` | `normal` | 여백 프리셋(mm)                                                                         |
| `hf`       | `1` · `0`                    | `1`      | 머리말/꼬리말 사용 여부                                                                      |
| `pdftitle` | 문자열                          | 자동       | 머리말 제목(프론트매터 `title` → H1 → 파일명 순)                                                 |
| `pdfdate`  | `YYYY-MM-DD`                 | 오늘       | 머리말 날짜(프론트매터 `date` 우선)                                                            |

📌 예시:

* 라이트 PDF:
  `.../html2pdf.html?doc=https://raw.githubusercontent.com/qubitsec/blog/refs/heads/main/content/ko/column/policy-proposal-doc-standards.md`
* 다크 PDF:
  `.../html2pdf.html?doc=...&pdftheme=dark`
* Letter + 넓은 여백:
  `.../html2pdf.html?doc=...&pagesize=letter&margin=wide`
* 제목/날짜 수동 지정:
  `.../html2pdf.html?doc=...&pdftitle=Policy%20Proposal&pdfdate=2025-09-13`

---

## 2) React + Tailwind 기반에서 지원하기

리액트 기반 프로젝트에서는
**`react-markdown`** 같은 라이브러리를 사용하면 쉽게 마크다운을 HTML처럼 보여줄 수 있습니다.

* Tailwind CSS의 **`prose` 클래스**를 적용하면 GitHub 스타일과 비슷하게 꾸밀 수 있습니다.
* 추가 플러그인(`remark-gfm`, `rehype-katex`, `rehype-sanitize`)을 사용하면
  표, 체크박스, 수식, 보안 처리까지 지원할 수 있습니다.
* 코드 블록은 `prism-react-renderer`로 하이라이트하여 보기 좋게 표시합니다.

📌 더 자세한 설정 방법과 예제 코드는 [`react.md`](./react.md) 문서를 참고하세요.

---

👉 **요약**

* **정적 HTML 방식**: 서버 설정이 단순하고, HTML+Markdown만 있으면 동작합니다.
* **React+Tailwind 방식**: 웹 애플리케이션 안에서 마크다운을 자연스럽게 보여주기에 좋습니다.
