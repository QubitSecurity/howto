## 1. Pretendard vs Noto Sans KR — 결론부터

### Pretendard가 더 잘 맞는 이유 (PLURA 같은 SaaS 대시보드 기준)

* 🎯 **한국어 웹 UI용으로 튜닝**

  * 관리자 화면, 테이블, 폼, 모달 같은 **웹 앱 UI**에 최적화된 느낌이라
    지금 PLURA 화면 스타일이랑 잘 어울립니다.
* 🖥 **시스템 폰트와 메트릭이 비슷**

  * macOS, Windows 시스템 폰트랑 줄 높이·폭이 잘 맞아서
    OS에 따라 줄 튀는 현상이 적어요.
* ⚙️ **파일 용량·가중치 선택이 유리**

  * 필요한 굵기만 골라 넣기 좋고, Noto Sans KR 풀셋보다
    번들 사이즈를 줄이기 쉽습니다.
* 🔒 **온프레미스/폐쇄망 배포에 적합**

  * 웹에서 받는 게 아니라, **제품 번들에 폰트 파일(woff2 등)을 포함**해서 설치하면 됨
  * 라이선스도 OFL 계열이라 상용 서비스/온프레미스 배포에 문제 없음(폰트 자체 수정·재배포지만 안 하면 거의 신경 안 써도 되는 수준)

### Noto Sans KR은 언제 좋냐?

* 📚 **문서·보고서·PDF, 프린트물** 등에 안정적인 인상을 주고 싶을 때
* 다국어(한·중·일) 섞인 문서에서 통일감이 필요할 때

UI 메인 폰트로 써도 되지만:

* Pretendard보다 **약간 둔탁하고 공간을 더 차지하는 느낌**
* 전체 굵기/글리프 포함하면 **폰트 파일 용량이 꽤 큼**

그래서 **“웹 앱 UI = Pretendard / 문서·PDF = Noto Sans KR도 고려”** 정도로 정리하는 게 좋아 보입니다.

---

## 2. “온라인에서 다운로드 불가” 환경에서 어떻게 쓰면 좋냐

CDN 못 쓰는 환경이니까:

1. **개발 PC에서 한 번만 폰트 파일 다운로드**

   * Pretendard `woff2` 몇 개(예: 400, 500, 600)만 추려서
   * `frontend/public/fonts/pretendard/` 같은 경로에 넣기

2. **전역 CSS에 @font-face 선언**

```css
@font-face {
  font-family: 'Pretendard';
  src: url('/fonts/pretendard/Pretendard-Regular.woff2') format('woff2');
  font-weight: 400;
  font-style: normal;
  font-display: swap;
}

@font-face {
  font-family: 'Pretendard';
  src: url('/fonts/pretendard/Pretendard-Medium.woff2') format('woff2');
  font-weight: 500;
  font-style: normal;
  font-display: swap;
}

@font-face {
  font-family: 'Pretendard';
  src: url('/fonts/pretendard/Pretendard-SemiBold.woff2') format('woff2');
  font-weight: 600;
  font-style: normal;
  font-display: swap;
}
```

3. **Tailwind 설정에서 등록**

```js
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      fontFamily: {
        plura: [
          'Pretendard',
          'ui-sans-serif',
          'system-ui',
          '-apple-system',
          'BlinkMacSystemFont',
          '"Segoe UI"',
          'sans-serif',
        ],
      },
    },
  },
};
```

4. **모달/토스트에 적용**

```tsx
// 모달 루트
<div className="font-plura text-[14px] leading-relaxed">
  ...
</div>

// Sonner Toaster
<Toaster className="font-plura text-[13px]" />
```

이렇게 하면:

* 클라우드 SaaS든 온프레미스든 **서버에서 폰트 파일을 함께 서빙**하니까
  외부 인터넷이 전혀 없어도 UI가 항상 Pretendard로 렌더링됩니다.

---

## 3. 요약

* **추천**: PLURA UI / 모달 / 토스트 → **Pretendard**
* Noto Sans KR은 필요하면 **문서/리포트·PDF용 서브 폰트**로 검토
* CDN 금지 환경이라도, **폰트 파일을 앱 번들에 포함 + @font-face + Tailwind `font-plura`** 패턴으로 쓰면 문제 없음
