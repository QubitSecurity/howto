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
