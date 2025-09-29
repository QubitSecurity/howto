# 표 정렬 가이드(React + Tailwind) — 개발 적용안

## 0) 요약(의사결정)

* **원칙 권장:** *텍스트는 좌측, 숫자/날짜는 우측*. 가독성과 업계 관례(엑셀·BI) 일치.  
* **실행 전략:** 지금 전면 수정 비용이 크므로 **현상 유지(좌측)** → 다음 업데이트에 “**열 타입 기반 자동 정렬**”을 테이블 공용 컴포넌트로 도입해 **일괄 전환**.

---

## 1) 왜 숫자는 우측 정렬인가

* **자릿수 끝(일의 자리) 정렬**로 비교 속도↑(횟수, 비율, 시간, 바이트 등).
* **도구 관례 부합**(엑셀·BI) → 사용자 기대와 일치.
* **스캔 가독성↑**: 합계/최댓값이 한눈에 들어옴.

---

## 2) 지금 전면 수정이 어려운 이유(타당)

* 다수 화면 재작업 필요.
* 다국어 환경에서 컬럼 폭/레이아웃 변동.
* 화면마다 개별 클래스 부여에 따른 운영비용↑.

---

## 3) 해법: “열 타입 기반 자동 정렬”

화면별 수작업 대신 **테이블 컴포넌트에 컬럼 메타데이터(type)** 를 주어 **규칙을 한 곳에서 통제**합니다.
→ 모든 표가 **동일 규칙**으로 자동 정렬, 정책 변경도 **한 군데** 수정으로 전역 반영.

### 권장 정렬 규칙

* **text →** `text-start`
* **number/date →** `text-end tabular-nums`
* **status/badge →** `text-center`
  ※ Tailwind v3.3+이면 `text-start / text-end` 사용(LTR/RTL 안전). v3.2 이하는 `text-left / text-right`.

---

## 4) 구현(React + Tailwind, TypeScript)

### 4.1 공용 Table 컴포넌트

```tsx
import React from "react";
import clsx from "clsx";

type ColumnType = "text" | "number" | "date" | "badge";

type Column<T> = {
  key: keyof T;
  header: string;
  type?: ColumnType;                 // 기본: text
  className?: string;                // 선택: 개별 커스텀
  render?: (row: T) => React.ReactNode; // 선택: 셀 렌더러
};

type DataTableProps<T> = {
  columns: Column<T>[];
  data: T[];
  rowKey: (row: T) => string | number;
};

const typeClass = (t: ColumnType = "text") =>
  clsx({
    // Tailwind v3.3+ (권장)
    "text-start": t === "text" || t === "badge",
    "text-end tabular-nums": t === "number" || t === "date",
    "text-center": t === "badge",
    // v3.2 이하면 아래로 대체:
    // "text-left": t === "text" || t === "badge",
    // "text-right tabular-nums": t === "number" || t === "date",
    // "text-center": t === "badge",
  });

export function DataTable<T>({ columns, data, rowKey }: DataTableProps<T>) {
  return (
    <div className="w-full overflow-x-auto">
      <table className="min-w-full table-fixed border-collapse">
        <thead className="bg-gray-50 dark:bg-gray-800">
          <tr>
            {columns.map((c) => (
              <th
                key={String(c.key)}
                className={clsx(
                  "px-3 py-2 text-xs font-semibold uppercase tracking-wide text-gray-600 dark:text-gray-300",
                  typeClass(c.type),
                  c.className
                )}
              >
                {c.header}
              </th>
            ))}
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-100 dark:divide-gray-700">
          {data.map((row) => (
            <tr
              key={rowKey(row)}
              className="odd:bg-white even:bg-gray-50/50 dark:odd:bg-gray-900 dark:even:bg-gray-900/60"
            >
              {columns.map((c) => (
                <td
                  key={String(c.key)}
                  className={clsx("px-3 py-2 text-sm", typeClass(c.type), c.className)}
                >
                  {c.render ? c.render(row) : String(row[c.key])}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
```

### 4.2 사용 예시

```tsx
type Row = {
  path: string;
  cookie: number;
  referer: number;
  ua: number;
  success: number;
  fail: number;
  hits: number;
  kind: string;
};

const columns = [
  { key: "path", header: "경로", type: "text", className: "truncate max-w-[220px]" },
  { key: "cookie", header: "쿠키", type: "number" },
  { key: "referer", header: "레퍼러", type: "number" },
  { key: "ua", header: "사용자에이전트", type: "number" },
  { key: "success", header: "성공", type: "number" },
  { key: "fail", header: "실패", type: "number" },
  { key: "hits", header: "횟수", type: "number" },
  { key: "kind", header: "유형", type: "badge", render: (r: Row) => (
      <span className="inline-flex items-center rounded-full border px-2 py-0.5 text-xs">
        {r.kind}
      </span>
    ) },
] satisfies Column<Row>[];

<DataTable<Row> columns={columns} data={rows} rowKey={(r)=> r.path} />
```

**포인트**

* `typeClass()` 한 곳에서 정렬 규칙 통제 → 전역 통일.
* `tabular-nums`로 숫자 폭 균일 → 세로 정렬 깔끔.
* 정책 변경시 `typeClass`만 수정하면 전 화면 동시 적용.

---

## 5) 점진적 전환 플랜

1. **현상 유지:** 당장 운영 리스크 최소화를 위해 기존 좌측 정렬 유지.
2. **공용 컴포넌트 도입:** 신규 화면부터 `DataTable` 사용.
3. **핵심 화면 우선 이관:** 탐지/리포트 등 숫자 비교 빈도가 높은 화면부터 적용.
4. **순차 확대:** 기존 화면 리팩터링 시 컬럼 메타(`type`)만 지정해 자동 정렬.
5. **정책 스위치 용이:** “숫자도 좌측” 등 정책 변화가 생겨도 `typeClass` 한 곳 수정으로 일괄 반영.

---

## 6) 예외/실무 팁

* **ID/코드(IP, 해시, 세션ID)** 는 비교보다 복사가 중요하면 **좌측** 유지.
* **단위 분리:** `360 ms`, `20 GB`는 값(number)과 단위(text)를 **분리 컬럼**으로 관리하면 정렬감↑.
* **숫자 포맷팅:** `Intl.NumberFormat("ko-KR")`로 천단위 구분자만 적용(표시 전용).
* **접근성:** 정렬 가능 헤더에 `aria-sort` 제공, 키보드 포커스 스타일 유지.
* **RTL 대비:** Tailwind `text-start / text-end` 사용으로 다국어 안전성 확보.

---

## 7) 최종 권고

* **UX 표준:** *텍스트 좌 / 숫자·날짜 우* + `tabular-nums`.
* **엔지니어링:** 화면 개별 수정 대신 **“열 타입 기반 자동 정렬”**을 공용 테이블로 구현하여 **통일성·가독성·유지보수성**을 동시에 확보.
* **로드맵:** 지금은 유지 → 다음 릴리스에 공용 컴포넌트로 **한 번에 전환**.
