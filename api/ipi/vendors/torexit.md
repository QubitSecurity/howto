아래는 **Tor Exit(토르 종료 노드) API “생성”(=사용) 방법**을 정리한 것입니다.
핵심: **Tor 프로젝트의 공식 엔드포인트는 공개(Open) API이므로 “키 발급 절차가 없습니다.”** 바로 호출하면 됩니다.

---

## ✅ Tor Exit API 사용 방법 (2025년 기준)

### 🔗 사용 가능한 공식 소스(무공개키·무료)

1. **Onionoo(토르 네트워크 상태 REST API)**

* 목적: 현재 동작 중인 **Exit 플래그가 붙은 릴레이** 목록 조회
* 인증: 불필요(무제한은 아님, 일반적인 공개 서비스 수준의 예절 준수)
* 베이스: `https://onionoo.torproject.org` ([metrics.torproject.org][1])

2. **Bulk Exit List(대량 종료 노드 목록)**

* 목적: **관측된 Exit IP의 단순 리스트**(빠르게 블록리스트/검증에 활용)
* 인증: 불필요
* 엔드포인트: `https://check.torproject.org/torbulkexitlist` 및 안내 페이지 `https://check.torproject.org/api/bulk` ([blog.torproject.org][2], [check.torproject.org][3])

> 보조(옵션): **TorDNSEL(DNS 질의 기반 확인)**, **ExoneraTor(과거 날짜 기준 조회)**. ([Server Fault][4], [metrics.torproject.org][5])

---

### 👤 계정 생성 또는 로그인

* **불필요**: 위 소스들은 **API Key 발급 절차가 없습니다.** 바로 cURL/HTTP로 호출합니다.
* Onionoo는 캐싱·압축 헤더 사용 권장(If-Modified-Since, Accept-Encoding). ([metrics.torproject.org][1])

---

### 🛡️ “API Key 확인 위치”

* 해당 없음(**무키**). 대신 아래 **요청 예시**를 참고해 바로 호출하세요.

---

### 📄 엔드포인트/요청 예시

#### 1) Onionoo로 “Exit 노드만” 받기

* **요청**

```bash
curl -s "https://onionoo.torproject.org/summary?flag=exit&limit=5000&fields=relays"
```

* **설명**: `flag=exit`으로 종료 노드만 필터링. 필요 시 `fields`로 응답 최소화, `limit`로 크기 제어. ([metrics.torproject.org][1])

* **추가 팁(성능/예절)**

  * 다음 호출 시 헤더 사용:

    * `If-Modified-Since: <이전 응답 Last-Modified>`, `Accept-Encoding: gzip` → 트래픽 절감. ([metrics.torproject.org][1])

#### 2) Bulk Exit List(단순 IP 리스트)

* **요청**

```bash
curl -sSL "https://check.torproject.org/torbulkexitlist"
```

* **설명**: **관측된 Exit IP**를 단순 텍스트 라인으로 반환(빠른 블록리스트 구축에 적합). 과거처럼 “포트별 정책 질의”는 지원하지 않으며 **일괄 리스트**를 제공합니다. ([blog.torproject.org][2])

#### 3) TorDNSEL(DNS 질의로 단건 확인)

* **요청(예: 12.34.56.78 확인)**

```bash
dig +short 78.56.34.12.dnsel.torproject.org
```

* **응답이** `127.0.0.2` 이면 **Tor Exit**로 간주. 자동화에 유용한 초경량 체크. ([Server Fault][4], [Tor Project][6])

#### 4) ExoneraTor(과거 날짜의 Tor 여부)

* **용도**: “해당 IP가 **특정 날짜**에 Tor 릴레이(Exit 포함)였는가?” 증빙용 조회. 웹/백엔드에서 활용. ([metrics.torproject.org][5])

---

### ✅ 확인 예시

* **Onionoo JSON 요약**: `... "relays":[{"a":["<IP1>","<IP2>"],"f":[...],"r":true,...}, ...]` 형태로 IP 목록(`a` 필드의 주소들)과 플래그를 포함. `flag=exit`를 줬으므로 **종료 노드만** 포함됩니다. ([metrics.torproject.org][1])
* **Bulk Exit List**는 줄 단위 IP만 반환(예: `185.220.101.1` 등). ([blog.torproject.org][2])

---

## 📌 활용 팁

| 목적                       | 추천 소스          | 장점                                         | 주의/비고                                                 |
| ------------------------ | -------------- | ------------------------------------------ | ----------------------------------------------------- |
| **실시간에 가까운 Exit IP 리스트** | Bulk Exit List | 구현 매우 간단(텍스트 라인)                           | 포트 정책별 세분 쿼리 미지원(2020년 변경) ([blog.torproject.org][2]) |
| **메타데이터까지 포함한 상세/필터링**   | Onionoo        | JSON·필터 풍부(`flag=exit`, `fields`, `limit`) | 캐싱/압축 헤더 사용 권장 ([metrics.torproject.org][1])          |
| **단건 즉시 확인**             | TorDNSEL       | DNS 한 번으로 여부 확인                            | 로컬 리졸버 정책 영향 가능 ([Server Fault][4], [Tor Project][6]) |
| **법적·포렌식용 과거 증빙**        | ExoneraTor     | 특정 날짜의 Tor 여부 증빙                           | 실시간 탐지용은 아님 ([metrics.torproject.org][5])             |

---

## 🧪 간단 스니펫

### Bash(블록리스트 파일 생성)

```bash
# 1) Bulk Exit List → ipset
curl -sSL "https://check.torproject.org/torbulkexitlist" > /tmp/tor_exits.txt
ipset create tor-exits hash:ip -exist
xargs -a /tmp/tor_exits.txt -r -n1 ipset add tor-exits 2>/dev/null
# iptables -A INPUT -m set --match-set tor-exits src -j DROP  # 정책은 환경에 맞춰 적용
```

(원리는 Bulk Exit List 활용 사례와 동일) ([Gist][7])

### Python(Onionoo→집합화)

```python
import requests
r = requests.get("https://onionoo.torproject.org/summary",
                 params={"flag":"exit","limit":"5000","fields":"relays"},
                 headers={"Accept-Encoding":"gzip"})
ips=set()
for relay in r.json().get("relays",[]):
    for addr in relay.get("a",[]):
        ips.add(addr.split(":")[0])  # IPv4/IPv6:포트 처리
print(len(ips), "exit IPs")
```

(Onionoo 파라미터와 압축 권장은 공식 문서 근거) ([metrics.torproject.org][1])

---

## ❗주의사항

* **Tor 사용=악성 아님**: 단순 차단은 서비스 특성상 오탐·차별 이슈가 생길 수 있습니다.
* **갱신 주기**: Exit 노드는 수시로 바뀝니다. \*\*정기 갱신(예: 10\~30분)\*\*을 권장합니다(캐시/조건부 요청으로 트래픽 최소화). ([metrics.torproject.org][1])
* **포트별 도달성**: 과거엔 “특정 IP/포트로 도달 가능한 Exit만” 필터가 있었지만, **현재는 단순 리스트 제공**으로 변경되었습니다. 정책 기반 필터는 자체 측정/방화벽 로직으로 보완하세요. ([blog.torproject.org][2])

---



[1]: https://metrics.torproject.org/onionoo.html "Sources – Tor Metrics"
[2]: https://blog.torproject.org/changes-tor-exit-list-service/?utm_source=chatgpt.com "Changes to the Tor Exit List Service"
[3]: https://check.torproject.org/api/bulk?utm_source=chatgpt.com "Bulk Tor Exit Exporter - TOR Check"
[4]: https://serverfault.com/questions/874327/how-can-i-check-if-ip-is-a-tor-exit-node?utm_source=chatgpt.com "How can I check if IP is a Tor exit node?"
[5]: https://metrics.torproject.org/exonerator.html?utm_source=chatgpt.com "ExoneraTor - Tor Metrics"
[6]: https://people.torproject.org/~weasel/tor-web-underlay/tordnsel/exitlist-spec.txt?utm_source=chatgpt.com "exitlist-spec.txt"
[7]: https://gist.github.com/jkullick/62695266273608a968d0d7d03a2c4185?utm_source=chatgpt.com "Block Tor Exit Nodes with IPTables"
