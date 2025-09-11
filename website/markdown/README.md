# 📄 Markdown Viewer 정리

Markdown 문서를 그대로 관리하면서, 사용자는 웹 브라우저에서 **HTML처럼 읽기 쉽게** 볼 수 있도록 하는 방법을 정리합니다.  
정적 웹 서버 환경과 React + Tailwind 기반 환경 두 가지 방식으로 구현할 수 있습니다.  


## 1) HTML만 서비스하는 정적 웹 서비스에서 지원하기

정적 웹 서버(Nginx, Apache 등)에서 **마크다운 파일을 직접 불러와 HTML로 렌더링**하는 방식입니다.  
아래처럼 `index.html` 하나만 두고, 쿼리 파라미터로 `doc` 값을 전달하면 됩니다.

- 예시:  
[PLURA Philosophy](https://w.plura.io/index.html?doc=/philosophy/ko/README.md)


- 동작 구조:  
- `index.html` → JavaScript로 `doc` 경로를 읽음  
- `fetch`로 마크다운 파일을 가져와서 → `markdown-it`, `highlight.js`, `KaTeX`, `Mermaid` 등을 이용해 브라우저에서 HTML로 변환  
- 따라서 **별도 서버 로직 없이 HTML만 서비스해도** 마크다운 문서를 HTML처럼 볼 수 있음  

---

## 2) React + Tailwind 기반에서 지원하기

리액트 프로젝트에서는 `react-markdown` 같은 라이브러리를 사용합니다.  
Tailwind의 `prose` 클래스를 함께 적용하면 GitHub 스타일로 예쁘게 보여줄 수 있습니다.

- 동작 구조:  
- React 컴포넌트에서 `content`(마크다운 문자열)를 받아서 → `react-markdown`으로 렌더링  
- `remark-gfm`, `rehype-katex`, `rehype-sanitize` 등 플러그인으로 GFM, 수식, 보안 지원  
- 코드 블록은 `prism-react-renderer` 등으로 하이라이트  

---
