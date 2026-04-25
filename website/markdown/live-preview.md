# 1. 권장 구조

```text
Markdown Source
   ↓
Editor / Textarea
   ↓
Markdown Parser
   ↓
Sanitize / Plugin 처리
   ↓
React Component Preview
   ↓
Copy / PDF / Dark Mode / Sync Scroll
```

가장 중요한 판단은 이것입니다.

> **HTML 문자열을 직접 만들어 `dangerouslySetInnerHTML`로 넣지 말고, Markdown을 React 컴포넌트로 렌더링하는 구조가 좋습니다.**

`react-markdown`은 마크다운 문자열을 React element로 안전하게 렌더링하고, plugin과 custom component를 붙일 수 있는 구조입니다. 공식 문서도 `dangerouslySetInnerHTML` 방식보다 React virtual DOM 기반 렌더링을 장점으로 설명합니다. ([GitHub][2])

---

# 2. 추천 라이브러리 조합

## 1안: 직접 구현 방식 — 추천

PLURA 웹 UI에 맞게 커스터마이징하려면 이 방식이 좋습니다.

```bash
npm install react-markdown remark-gfm rehype-sanitize
npm install github-markdown-css
```

코드 블록 하이라이트가 필요하면 추가합니다.

```bash
npm install rehype-highlight highlight.js
```

PDF 출력 버튼을 넣고 싶으면 초기에는 별도 라이브러리보다 `window.print()` + print CSS 방식이 가장 단순합니다.

```bash
npm install react-to-print
```

선택적으로 설치할 수 있습니다.

---

## 2안: 완성형 에디터 사용

빠르게 만들려면 `@uiw/react-md-editor`도 괜찮습니다.

```bash
npm install @uiw/react-md-editor
```

이 라이브러리는 React/TypeScript 기반 마크다운 에디터와 preview를 제공하고, GitHub Flavored Markdown과 dark mode도 지원합니다. ([GitHub][3])

다만 PLURA 스타일, 버튼, 보안 처리, PDF 출력, 동기 스크롤 등을 세밀하게 제어하려면 직접 구현 방식이 더 좋습니다.

---

# 3. 기능별 구현 방법론

## 1) Markdown Preview

기본 렌더링은 `react-markdown`으로 처리합니다.

```tsx
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import rehypeSanitize from "rehype-sanitize";
import "github-markdown-css/github-markdown.css";

type MarkdownViewerProps = {
  content: string;
};

export function MarkdownViewer({ content }: MarkdownViewerProps) {
  return (
    <article className="markdown-body">
      <ReactMarkdown
        remarkPlugins={[remarkGfm]}
        rehypePlugins={[rehypeSanitize]}
      >
        {content}
      </ReactMarkdown>
    </article>
  );
}
```

`remark-gfm`을 쓰면 표, 체크박스, 취소선 같은 GitHub 스타일 마크다운을 지원할 수 있습니다. `react-markdown` 공식 예제도 GFM 확장을 위해 `remark-gfm`을 사용하는 방식을 안내합니다. ([GitHub][2])

---

## 2) Editor 영역

초기 버전은 `textarea`로 충분합니다.

```tsx
type MarkdownEditorProps = {
  value: string;
  onChange: (value: string) => void;
};

export function MarkdownEditor({ value, onChange }: MarkdownEditorProps) {
  return (
    <textarea
      value={value}
      onChange={(e) => onChange(e.target.value)}
      spellCheck={false}
      className="markdown-editor"
    />
  );
}
```

고급 편집 기능이 필요하면 CodeMirror를 붙이면 됩니다. CodeMirror는 `@codemirror` scope의 npm 패키지로 제공되고, 브라우저에서는 bundler 또는 loader가 필요합니다. ([CodeMirror][4])

```bash
npm install @uiw/react-codemirror @codemirror/lang-markdown
```

---

## 3) Live Preview

React state 하나로 editor와 viewer를 연결합니다.

```tsx
import { useState } from "react";
import { MarkdownEditor } from "./MarkdownEditor";
import { MarkdownViewer } from "./MarkdownViewer";

const defaultMarkdown = `# Markdown Viewer

- 실시간 미리보기
- 표 지원
- 코드 블록 지원

| 항목 | 설명 |
|---|---|
| React | UI |
| Markdown | 문서 |
`;

export default function MarkdownLivePreview() {
  const [markdown, setMarkdown] = useState(defaultMarkdown);

  return (
    <div className="markdown-live-preview">
      <div className="toolbar">
        <button onClick={() => setMarkdown(defaultMarkdown)}>Reset</button>
        <button onClick={() => navigator.clipboard.writeText(markdown)}>
          Copy
        </button>
        <button onClick={() => window.print()}>Export PDF</button>
      </div>

      <div className="split">
        <MarkdownEditor value={markdown} onChange={setMarkdown} />
        <MarkdownViewer content={markdown} />
      </div>
    </div>
  );
}
```

---

# 4. 보안 처리

마크다운 viewer에서 가장 중요한 부분은 **XSS 방어**입니다.

주의할 점은 다음입니다.

```tsx
// 권장하지 않음
<div dangerouslySetInnerHTML={{ __html: html }} />
```

특히 `marked` 같은 라이브러리는 빠른 Markdown-to-HTML 변환에는 좋지만, 공식 문서에서 출력 HTML을 sanitize하지 않는다고 경고합니다. 따라서 안전하지 않은 문자열을 처리할 때는 DOMPurify 같은 별도 필터링이 필요합니다. ([marked.js.org][5])

PLURA 관리 UI에 넣는다면 기본 정책은 아래가 좋습니다.

```text
기본 정책:
- raw HTML 비허용
- script, iframe, object, embed 차단
- 외부 링크는 target="_blank" + rel="noopener noreferrer"
- 이미지 URL 제한 가능
- 필요 시 rehype-sanitize 적용
```

---

# 5. Copy 기능

Copy 버튼은 두 가지로 나눌 수 있습니다.

```text
1. Markdown 원문 복사
2. Preview 결과 HTML 복사
```

초기에는 **Markdown 원문 복사**만 제공하는 것이 좋습니다.

```tsx
async function copyMarkdown(markdown: string) {
  await navigator.clipboard.writeText(markdown);
}
```

Preview HTML 복사는 브라우저/메일/문서 붙여넣기 호환성 이슈가 있어 2차 단계로 두는 것이 좋습니다.

---

# 6. Export PDF

초기 구현은 가장 단순하게 갑니다.

```tsx
<button onClick={() => window.print()}>
  Export PDF
</button>
```

그리고 CSS에서 editor와 toolbar를 숨깁니다.

```css
@media print {
  .toolbar,
  .markdown-editor {
    display: none;
  }

  .split {
    display: block;
  }

  .markdown-body {
    width: 100%;
  }
}
```

이 방식은 브라우저의 “PDF로 저장” 기능을 활용하므로 안정적입니다.

고급 PDF가 필요하면 나중에 아래 방향으로 확장합니다.

```text
1단계: window.print()
2단계: react-to-print
3단계: 서버에서 Puppeteer로 PDF 생성
```

관리자용 문서 viewer라면 1단계 또는 2단계가 충분합니다.

---

# 7. Sync Scroll

좌측 editor와 우측 preview의 스크롤을 동기화하려면 비율 방식으로 처리합니다.

```tsx
function syncScroll(source: HTMLElement, target: HTMLElement) {
  const sourceMax = source.scrollHeight - source.clientHeight;
  const targetMax = target.scrollHeight - target.clientHeight;

  if (sourceMax <= 0 || targetMax <= 0) return;

  const ratio = source.scrollTop / sourceMax;
  target.scrollTop = ratio * targetMax;
}
```

다만 마크다운은 source line과 preview height가 1:1로 맞지 않습니다.

그래서 초기 버전은 다음 수준이면 충분합니다.

```text
- Sync scroll ON/OFF 옵션 제공
- ON일 때 단순 비율 동기화
- 긴 문서에서는 완벽한 줄 단위 동기화보다 UX 안정성 우선
```

정교하게 하려면 markdown AST 기준으로 heading 위치를 매핑해야 합니다.

---

# 8. Dark Mode

Dark mode는 React state 또는 기존 PLURA theme 상태와 연결하면 됩니다.

```tsx
const [darkMode, setDarkMode] = useState(false);

return (
  <div className={darkMode ? "viewer dark" : "viewer"}>
    <button onClick={() => setDarkMode(!darkMode)}>
      Dark mode
    </button>
  </div>
);
```

CSS는 다음처럼 구성합니다.

```css
.viewer {
  background: #ffffff;
  color: #24292f;
}

.viewer.dark {
  background: #0d1117;
  color: #c9d1d9;
}

.viewer.dark .markdown-body {
  background: #0d1117;
  color: #c9d1d9;
}
```

---

# 9. 파일 구조 예시

```text
src/
  components/
    markdown/
      MarkdownLivePreview.tsx
      MarkdownEditor.tsx
      MarkdownViewer.tsx
      MarkdownToolbar.tsx
      markdown.css
  utils/
    markdown/
      sanitize.ts
      syncScroll.ts
      downloadMarkdown.ts
```

PLURA 관리 UI에 넣는다면 메뉴 구조는 이런 식이 좋습니다.

```text
문서 관리
 └─ Markdown Viewer
     ├─ 편집
     ├─ 미리보기
     ├─ 복사
     ├─ PDF 출력
     └─ 다크 모드
```

---

# 10. PLURA 기준 추천 개발 순서

## 1단계: MVP

```text
- textarea 입력
- react-markdown preview
- remark-gfm 적용
- copy markdown
- reset
- dark mode
```

## 2단계: 문서 viewer 완성

```text
- PDF 출력
- sync scroll
- localStorage 자동 저장
- 파일 열기 .md
- 파일 다운로드 .md
```

## 3단계: 운영 기능

```text
- 문서 템플릿 선택
- PLURA 문서 스타일 CSS 적용
- 보안 정책 기반 HTML 제한
- 이미지 업로드 제한
- 관리자 권한별 편집/보기 분리
```

## 4단계: 고급 기능

```text
- TOC 자동 생성
- heading anchor 생성
- 코드 블록 syntax highlight
- Mermaid diagram 지원
- 서버 저장
- 문서 버전 관리
```

---

# 결론

PLURA React 환경에서는 **완성형 에디터를 바로 붙이는 것보다**, 아래 조합으로 직접 만드는 것을 추천합니다.

```bash
npm install react-markdown remark-gfm rehype-sanitize github-markdown-css
```

핵심 구조는 다음입니다.

```text
textarea 또는 CodeMirror
→ React state
→ react-markdown
→ remark-gfm
→ rehype-sanitize
→ PLURA 스타일 preview
```

이 방식이 좋은 이유는 **보안 통제, UI 커스터마이징, PDF 출력, 다크 모드, PLURA 문서 스타일 적용**을 모두 직접 제어할 수 있기 때문입니다.

[1]: https://markdownlivepreview.com/ "Markdown Live Preview"
[2]: https://github.com/remarkjs/react-markdown "GitHub - remarkjs/react-markdown: Markdown component for React · GitHub"
[3]: https://github.com/uiwjs/react-md-editor "GitHub - uiwjs/react-md-editor: A simple markdown editor with preview, implemented with React.js and TypeScript. · GitHub"
[4]: https://codemirror.net/docs/ref/ "CodeMirror Reference Manual"
[5]: https://marked.js.org/ "Marked Documentation"
