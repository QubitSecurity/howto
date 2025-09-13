# 📄 React + Tailwind 기반 Markdown Viewer

이 문서는 **React + Tailwind** 환경에서 마크다운을  
“마치 HTML처럼 보기 좋게” 렌더링하는 방법을 정리한 것입니다.  

---

## 1) 패키지 설치

```bash
# 마크다운 렌더 + 확장 (GFM, 수식), 보안, 코드 하이라이트
npm i react-markdown remark-gfm remark-math rehype-katex rehype-sanitize
npm i prism-react-renderer
npm i katex
````

---

## 2) Tailwind 설정 (typography 플러그인)

```bash
npm i -D @tailwindcss/typography
```

`tailwind.config.js`:

```js
module.exports = {
  content: ["./src/**/*.{js,ts,jsx,tsx}"],
  theme: { extend: {} },
  plugins: [require("@tailwindcss/typography")],
};
```

글로벌 CSS(예: `src/index.css`)에 KaTeX 스타일 추가:

```css
@import "katex/dist/katex.min.css";
```

---

## 3) Markdown 컴포넌트

아래 컴포넌트는 다음 기능을 포함합니다.

* GitHub Flavored Markdown (표·체크박스·테이블)
* 수식 렌더링 (remark-math + KaTeX)
* 안전한 렌더링 (rehype-sanitize)
* 코드 블록 하이라이트 (prism-react-renderer) + “Copy” 버튼
* Tailwind Typography(`prose` 클래스) 적용

```tsx
// src/components/Markdown.tsx
import React, { useMemo } from "react";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import remarkMath from "remark-math";
import rehypeSanitize from "rehype-sanitize";
import { defaultSchema } from "hast-util-sanitize";
import rehypeKatex from "rehype-katex";
import { Prism as SyntaxHighlighter } from "prism-react-renderer";
import type { Components } from "react-markdown";

type Props = {
  content: string;
  className?: string;
};

const schema = {
  ...defaultSchema,
  attributes: {
    ...defaultSchema.attributes,
    code: [...(defaultSchema.attributes?.code || []), ["className"]],
    span: [...(defaultSchema.attributes?.span || []), ["className"]],
  },
};

const CodeBlock: Components["code"] = ({ className, children, inline }) => {
  const code = String(children ?? "");
  const lang = (className || "").replace(/language-/, "");

  if (inline) {
    return (
      <code className="rounded bg-gray-100 px-1 py-0.5 text-[0.95em]">
        {code}
      </code>
    );
  }

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(code);
    } catch {}
  };

  return (
    <div className="relative group">
      <button
        onClick={handleCopy}
        className="absolute right-2 top-2 hidden rounded-md border px-2 py-1 text-xs group-hover:block"
      >
        Copy
      </button>
      <SyntaxHighlighter language={lang || undefined}>
        {code.trimEnd()}
      </SyntaxHighlighter>
    </div>
  );
};

export default function Markdown({ content, className }: Props) {
  const components: Components = useMemo(
    () => ({
      code: CodeBlock,
      a: ({ href, children, ...props }) => (
        <a
          href={href}
          target="_blank"
          rel="noopener noreferrer"
          className="underline underline-offset-4"
          {...props}
        >
          {children}
        </a>
      ),
      table: ({ children }) => (
        <div className="my-4 w-full overflow-x-auto">
          <table className="w-full">{children}</table>
        </div>
      ),
      img: ({ src, alt }) => (
        <img src={src || ""} alt={alt || ""} className="max-h-[480px] w-auto" />
      ),
    }),
    []
  );

  return (
    <div className={`prose prose-neutral max-w-none dark:prose-invert ${className || ""}`}>
      <ReactMarkdown
        remarkPlugins={[remarkGfm, remarkMath]}
        rehypePlugins={[[rehypeSanitize, schema], rehypeKatex]}
        components={components}
      >
        {content}
      </ReactMarkdown>
    </div>
  );
}
```

---

## 4) 사용 예시

```tsx
// src/pages/Example.tsx
import Markdown from "@/components/Markdown";

const sample = `
# Hello Markdown

- GFM 체크박스
  - [x] done
  - [ ] todo

표:

| A | B |
|---|---|
| 1 | 2 |

수식: 인라인 $E=mc^2$ 와 블록

$$
\\int_a^b f(x)dx
$$

코드:

\`\`\`ts
function greet(name: string) {
  return \`Hello, \${name}\`;
}
\`\`\`
`;

export default function Example() {
  return (
    <div className="px-6 py-10">
      <Markdown content={sample} />
    </div>
  );
}
```

---

## 5) 추가 옵션

* **Mermaid 다이어그램**: \`\`\`mermaid 블록을 감지해 `<Mermaid />` 컴포넌트로 렌더링
* **앵커 링크/TOC**: 헤딩에 id 부여 → 목차 생성
* **이미지 확대**: 클릭 시 라이트박스/모달 표시
* **보안**: `rehype-sanitize` 유지 (가능한 한 `rehype-raw`는 피할 것)

---


