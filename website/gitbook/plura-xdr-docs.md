아래는 **GitBook SaaS**에서 언어별 + 버전별 문서를 관리하기 위한 **구조 예시 설정**입니다.

---

## 🗂️ 1. 전체 구조 개요

```
Docs site: Korean
├── Space: Korean v5.5
├── Space: Korean v6.0

Docs site: Japanese
├── Space: Japanese v5.5
├── Space: Japanese v6.0
```

각 `Docs site`는 해당 언어에 대한 문서 모음이며, 그 안에 버전별로 `Spaces`를 나누어 관리합니다.

---

## ⚙️ 2. 설정 방법 (GitBook SaaS 기준)

### 📘 Step 1: Space 생성

1. GitBook 좌측 상단 \*\*"Spaces"\*\*에서 `+ Create a space`
2. 이름 예시:

   * `Korean v5.5`
   * `Korean v6.0`
   * `Japanese v5.5`
   * `Japanese v6.0`
3. 각 Space 안에서 `README`, `SUMMARY`, 목차 등 문서 작성

> 🔒 참고: 각 Space는 독립적이므로 협업자, 공개 여부, 콘텐츠 등을 개별 관리할 수 있습니다.

---

### 🌐 Step 2: Docs site 생성 및 구성

1. GitBook 좌측 상단 **"Docs sites" > + New Docs Site** 클릭

2. 예시:

   * `Korean`
   * `Japanese`

3. 해당 Docs site에 들어가서:

   * **"Spaces" 탭** 선택
   * `+ Add space` 버튼을 클릭해 아래 항목들을 연결:

     * `Korean v5.5`
     * `Korean v6.0`
   * (일본어 문서도 동일 방식)

4. 필요한 경우 사이트 내에서 각 버전을 메뉴 형태로 표시되도록 설정 가능

---

## 🧭 3. 사용자 경험 예시 (URL 기준)

| 링크                                             | 설명          |
| ---------------------------------------------- | ----------- |
| `https://yourcompany.gitbook.io/korean/v5.5`   | 한국어 문서 v5.5 |
| `https://yourcompany.gitbook.io/korean/v6.0`   | 한국어 문서 v6.0 |
| `https://yourcompany.gitbook.io/japanese/v5.5` | 일본어 문서 v5.5 |

> `Docs site` 주소는 고정되어 있고, 그 안에서 버전(Space)별로 이동하게 됩니다.

---

## 💡 팁: Docs site 메뉴 구성

각 버전을 구분해서 메뉴에 표시하고 싶다면:

* `Docs site > Navigation` 메뉴에서 **Manual Navigation**으로 설정
* 다음과 같이 구성 가능:

```txt
📚 Korean Docs
├─ v5.5 → Korean v5.5 Space 연결
├─ v6.0 → Korean v6.0 Space 연결
```

---

## ✅ 정리

| 구성 요소         | 설명                                 |
| ------------- | ---------------------------------- |
| **Space**     | 버전별 문서를 담는 개별 문서 단위                |
| **Docs Site** | 언어별로 여러 Space를 묶는 상위 그룹            |
| **이점**        | 언어/버전 관리가 명확하고 보기 쉬움, 협업/권한 분리가 쉬움 |

---

