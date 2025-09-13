# 📄 Markdown Viewer 정리

이 문서는 **Markdown(마크다운)** 형식으로 작성된 문서를  
웹 브라우저에서 **HTML 문서처럼 보기 쉽게** 보여주는 방법을 정리한 것입니다.  

즉, 마크다운 파일을 그대로 저장하고 관리하면서도,  
사용자는 웹 브라우저에서 깔끔하게 읽을 수 있도록 만드는 방법입니다.  
크게 두 가지 방식이 있습니다.  

---

## 1) HTML만 서비스하는 정적 웹 서비스에서 지원하기

가장 간단한 방법은 **정적 웹 서버(Nginx, Apache 등)** 에  
샘플 `index.html` 파일만 두고 사용하는 방식입니다.  

- 브라우저 주소창에서 `?doc=...` 값을 주면, 해당 마크다운 문서를 불러와서 HTML로 변환해 보여줍니다.
- 서버에는 별도의 프로그램을 설치할 필요가 없습니다.  
- 즉, **HTML과 마크다운 파일만 있으면 바로 동작**합니다.  

📌 예시  
   [PLURA Philosophy](https://w.plura.io/index.html?doc=/philosophy/ko/README.md)


📌 동작 구조  
1. `index.html`이 `doc` 파라미터(파일 경로)를 읽습니다.  
2. JavaScript가 `fetch`로 마크다운 파일을 가져옵니다.  
3. `markdown-it`, `highlight.js`, `KaTeX`, `Mermaid` 같은 라이브러리가  
   내용을 HTML로 바꿔 브라우저에 표시합니다.  

4. 예제 코드는 [`index.html`](./html/filename-index.html) 문서를 참고하세요.

---

## 2) React + Tailwind 기반에서 지원하기

리액트 기반 프로젝트에서는  
**`react-markdown`** 같은 라이브러리를 사용하면 쉽게 마크다운을 HTML처럼 보여줄 수 있습니다.  

- Tailwind CSS의 **`prose` 클래스**를 적용하면 GitHub 스타일과 비슷하게 꾸밀 수 있습니다.  
- 추가 플러그인(`remark-gfm`, `rehype-katex`, `rehype-sanitize`)을 사용하면  
  표, 체크박스, 수식, 보안 처리까지 지원할 수 있습니다.  
- 코드 블록은 `prism-react-renderer`로 하이라이트하여 보기 좋게 표시합니다.  

📌 더 자세한 설정 방법과 예제 코드는 [`react.md`](./react.md) 문서를 참고하세요.

---

👉 요약  
- **정적 HTML 방식**: 서버 설정이 단순하고, HTML+Markdown만 있으면 동작합니다.  
- **React+Tailwind 방식**: 웹 애플리케이션 안에서 마크다운을 자연스럽게 보여주기에 좋습니다.  
