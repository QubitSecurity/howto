아래는 요청하신 구조(상단 디자인 영역 + 왼쪽 달력 + 가운데 iframe)를 반영한 **HTML 레이아웃 예시 코드**입니다.
반응형 기본 스타일과 함께 간단한 UI 구성도 포함했습니다.

---

### ✅ 구성 설명:

* **상단(Header)**: 디자인 영역입니다. 로고나 제목 등을 표시할 수 있습니다.
* **왼쪽(Sidebar)**: 달력이 들어가는 자리입니다 (`<input type="date">` 또는 JS 달력 가능).
* **가운데(Main)**: GitHub에서 만든 파일 리스트를 띄우는 `iframe`입니다.

---

### ✅ HTML 코드 예시

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>GitHub Viewer Layout</title>
  <style>
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }

    body, html {
      height: 100%;
      font-family: Arial, sans-serif;
    }

    header {
      height: 60px;
      background-color: #282c34;
      color: white;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 24px;
      font-weight: bold;
    }

    .container {
      display: flex;
      height: calc(100% - 60px);
    }

    aside {
      width: 200px;
      background-color: #f3f3f3;
      padding: 20px;
      border-right: 1px solid #ccc;
    }

    main {
      flex-grow: 1;
      padding: 0;
      overflow: hidden;
    }

    iframe {
      width: 100%;
      height: 100%;
      border: none;
    }

    .calendar-label {
      margin-bottom: 8px;
      font-weight: bold;
    }
  </style>
</head>
<body>

  <header>
    🎨 디자인 상단 영역
  </header>

  <div class="container">
    <aside>
      <div class="calendar-label">📅 날짜 선택</div>
      <input type="date" id="calendar">
    </aside>

    <main>
      <iframe src="https://your-github-page-url/index.html" title="GitHub 파일 리스트"></iframe>
    </main>
  </div>

</body>
</html>
```

---

### ✅ 사용 팁

* `iframe src`에는 GitHub Pages로 배포된 HTML 파일 URL을 넣으세요.
  예: `https://USERNAME.github.io/REPO/index.html`

* 더 고급 달력이 필요하면 `flatpickr`, `fullcalendar`, `vanilla-calendar` 같은 JS 라이브러리를 사용할 수 있습니다.

---

필요 시 `iframe` 내부에서 GitHub API를 활용해 파일 리스트를 직접 출력하는 방식도 설명드릴 수 있어요.
