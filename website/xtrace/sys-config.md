`index.html` 내부 `<iframe>`에 표시될 페이지에서 `.data` 파일을 읽고 목록을 출력할 JavaScript를 **외부 파일로 분리**해 `index.html`에 포함하는 방식으로 구성하겠습니다.

---

### ✅ 1. `index.html` 수정 예시

아래는 `iframe`에 들어갈 HTML 파일 (`index.html`) 예시입니다.
`2025.data`를 읽고 `<ul>`로 목록을 생성하며, 외부 JS 파일(`render-list.js`)을 불러옵니다.

```html
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>2025 티켓 리스트</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      padding: 20px;
    }
    h2 {
      margin-bottom: 10px;
    }
    ul {
      list-style: none;
      padding-left: 0;
    }
    li {
      margin-bottom: 6px;
    }
    a {
      text-decoration: none;
      color: #0366d6;
    }
    a:hover {
      text-decoration: underline;
    }
  </style>
</head>
<body>

  <h2>📂 2025 티켓 목록</h2>
  <ul id="ticket-list"></ul>

  <script src="render-list.js"></script>

</body>
</html>
```

---

### ✅ 2. 외부 JavaScript (`render-list.js`)

아래 내용을 `render-list.js`라는 파일로 저장하고, `index.html`과 같은 디렉터리에 두세요:

```javascript
const DATA_URL = '2025.data';  // .data 파일 경로
const BASE_URL = 'https://your-github-page-url/tickets';  // 티켓 HTML 경로

fetch(DATA_URL)
  .then(response => response.text())
  .then(data => {
    const listContainer = document.getElementById('ticket-list');
    const lines = data.trim().split('\n');

    lines.forEach(line => {
      const [monthStr, entries] = line.split('|');
      const month = monthStr.padStart(2, '0');

      if (!entries) return;

      const items = entries.split(',');

      items.forEach(item => {
        const [dayStr, ...ids] = item.split(':');
        const day = dayStr.padStart(2, '0');

        ids.forEach(id => {
          const li = document.createElement('li');
          const a = document.createElement('a');
          a.href = `${BASE_URL}/2025/${month}/${day}/${id}.html`;
          a.textContent = `2025년 ${parseInt(month)}월 ${parseInt(day)}일 (#${id})`;
          li.appendChild(a);
          listContainer.appendChild(li);
        });
      });
    });
  })
  .catch(error => {
    console.error('데이터 파일을 불러오는 중 오류 발생:', error);
  });
```

---

### ✅ 디렉터리 구조 예시

```
/
├── index.html               ← iframe에 표시될 HTML
├── render-list.js           ← 목록 생성 스크립트
├── 2025.data                ← 날짜별 ID 데이터
```

---

필요하시면 `2024.data` 파일도 선택 가능하도록 연도별 `<select>` 기능 추가도 해드릴 수 있어요.
