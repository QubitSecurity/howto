# PLURA-XDR Unified Log Analysis - 보고서

## 요약(한 문단)

2025-09-01 01:42:36Z(로컬 10:42:36+09:00) `QA-WAF-Stg` 리눅스 호스트에서 `auditd` **EXECVE** 이벤트로 `curl -s hxxps://repo.plura[.]io/v5/module/upgrade_geoip.sh` 실행이 포착되었습니다. 행위 자체는 **외부 스크립트 전송(T1105)** 에 해당하며, TI 부가정보로 **AbuseIPDB 85(124회 신고)**, **VT 7/70=10.0% 악성**이 제공되었습니다. 단, TI 지표의 **대상(IP/도메인) 연계가 raw\_log에서 확인 불가**하여 맥락 검증이 필요합니다. 현재 단계 평가는 **3단계(경계)** 로 보되, 해당 URL이 **사내·공식 배포 저장소**임이 확인되면 **2단계(주의)** 로 하향 가능합니다.

---

## 위험도 평가 (1\~4단계 + 근거 요약)

**현재 평가: 3단계(경계)**

* **외부 스크립트 전송/실행**: `EXECVE`로 `curl` 사용 → **MITRE T1105** 직접 매칭.
* **TI 수치(원문 병기)**: VT **7/70=10.0% 악성**, **3/70=4.3% 의심**, **60/70=85.7% 정상**, Reputation **-15**. AbuseIPDB **confidence 85**/**reports 124**(분류: SSH Brute-Force, Spamming).
* **맥락 불확실성**: raw\_log에 **연결 대상 IP/해석 대상의 일치 여부 불명** → 오탐/정탐 판별 위해 **도메인 소유·변조 여부**와 **실제 해석된 IP** 검증 필요.
* **하향 조건**: `repo.plura.io`가 **공식 배포 저장소**이고 스크립트 **무결성(해시/서명)** 확인 시 **2단계(주의)**.

---

## 근거 상세 (표)

| field             | value                                                | why\_it\_matters                       |
| ----------------- | ---------------------------------------------------- | -------------------------------------- |
| event.type        | `EXECVE`                                             | 프로세스 실행 이벤트로 **행위 기반 탐지**의 핵심.         |
| event.programname | `audispd`                                            | auditd 파이프라인을 통해 캡처됨. 신뢰 가능한 커널 감시 경로. |
| event.argc        | `3`                                                  | 인자 수 일치 확인(명령 라인 완전성).                 |
| event.a0          | `curl`                                               | 외부 자원 전송/다운로드 도구. **T1105** 연계.        |
| event.a1          | `-s`                                                 | Silent 옵션: **로그/출력 최소화** 시도 가능성.       |
| event.a2          | `hxxps://repo.plura[.]io/v5/module/upgrade_geoip.sh` | **외부 스크립트** 직접 실행 가능 경로. 출처 검증 필요.     |
| host.computer     | `QA-WAF-Stg`                                         | 스테이징/테스트 환경일 수 있음(운영 영향도 판단에 중요).      |
| host.channel      | `auditd/syslog`                                      | 수집 채널(감사 정확성/커버리지 판단).                 |
| time(UTC/local)   | `2025-09-01T01:42:36.681968Z` / `+09:00`             | 타임라인 상 **동시 다발 행위 상관**에 필요.            |

---

## 환경 맥락 (호스트/세션/권한/베이스라인 편차)

| host       | os    | channel       | user      | session   | privileges | baseline\_deviation                                               |
| ---------- | ----- | ------------- | --------- | --------- | ---------- | ----------------------------------------------------------------- |
| QA-WAF-Stg | linux | auditd/syslog | **확인 불가** | **확인 불가** | **확인 불가**  | WAF 스테이징에서 **정기 GeoIP 업데이트 스크립트**가 존재한다면 **정상 베이스라인일 수 있음**(미확인). |

> 권한·사용자·세션 식별은 추가 로그(audit UID/TTY/PPID, shell history, systemd journal) 연계 필요.

---

## IOC/IOA 목록 (차단·모니터링용)

| type        | indicator                                                    | context             | confidence       | ttl |
| ----------- | ------------------------------------------------------------ | ------------------- | ---------------- | --- |
| IOA-command | `curl -s hxxps://repo.plura[.]io/v5/module/upgrade_geoip.sh` | 외부 스크립트 전송/실행 시도    | Medium           | 30d |
| Domain      | `repo.plura[.]io`                                            | **공식 저장소 여부 확인 필요** | Low\~High(맥락 의존) | 7d  |
| URL         | `hxxps://repo.plura[.]io/v5/module/upgrade_geoip.sh`         | 스크립트 무결성/서명 검증 필요   | Medium           | 7d  |
| ASN         | `AS12345 EvilISP`                                            | TI 제공값(맥락 불명확)      | Low              | 7d  |
| GeoIP       | `RU`                                                         | 운영 영역과 불일치 시 주의     | Low              | 7d  |

---

## MITRE ATT\&CK 매핑

* **T1105 – Ingress Tool Transfer**: `curl`을 이용한 외부 콘텐츠 전송/가져오기.
* (보조) **T1059.004 – Command and Scripting Interpreter: Unix Shell**: 쉘을 통한 명령 실행(맥락상 가능).
* (상황부합 시) **T1071.001 – Application Layer Protocol: Web Protocols**: HTTP(S) 전송 경로 활용.

---

## TI 해석 (VT/AbuseIPDB/GeoIP) + 계산식 제시

| source     | metric             | value                    | interpretation                                                |
| ---------- | ------------------ | ------------------------ | ------------------------------------------------------------- |
| VirusTotal | malicious / total  | **7/70 = 10.0%**         | 악성 의심이 **소수 엔진**에 존재. 단독 판단 근거로는 부족.                          |
| VirusTotal | suspicious / total | **3/70 = 4.3%**          | 소수 의심. 컨텍스트 필요.                                               |
| VirusTotal | harmless / total   | **60/70 = 85.7%**        | 다수 엔진이 무해 판정.                                                 |
| VirusTotal | reputation         | **-15**                  | 커뮤니티 평판이 다소 부정적. 출처·콘텐츠 교차검증 필요.                              |
| AbuseIPDB  | confidence\_score  | **85**                   | 우리 기준 **4단계(위기) 후보** 수치. 단, **대상 IP=무엇인지** 사건과의 **연계 확인 필요**. |
| AbuseIPDB  | total\_reports     | **124**                  | 과거 반복 신고. 카테고리: **SSH Brute-Force, Spamming**.                |
| GeoIP      | country / ASN      | **RU / AS12345 EvilISP** | 운영국가·프로바이더와 불일치 시 위험도 가중. **도메인 실제 해석 IP** 확인 필수.             |

> **계산식**: 총계 = 7(악성)+3(의심)+60(정상)=**70** → 비율 = (분자/70)×100.

---

## 오탐 가능성 및 판별 근거

* **오탐 가능성**: `repo.plura.io`가 **공식 배포 저장소**이고 `upgrade_geoip.sh`가 **정상 업데이트 스크립트**라면 합리적 활동.
* **정탐 가능성**: 도메인/URL **스쿼팅·변조**(동일 도메인 유사 철자, DNS 하이재킹), **MITM**, 또는 정상 스크립트 내부에 **외부 페이로드 2차 다운로드** 로직 존재 시.
* **판별 핵심**

  1. **DNS 해석 결과(IP·ASN·국가)** 가 TI 블록과 일치하는지.
  2. **스크립트 해시/서명**(SHA-256)과 **레퍼런스 해시** 일치 여부.
  3. **배포 경로 고정(핀닝)**: 도메인/인증서/해시 핀닝 정책 적용 여부.
  4. **동일 호스트의 과거 베이스라인**: 동일 명령이 정기적으로, 동일 시각대에 반복되었는지.

---

## 대응 체크리스트 (즉시/단기/중기)

| evidence\_ref          | next\_action                                      | tool\_policy                                   | scope    | status |
| ---------------------- | ------------------------------------------------- | ---------------------------------------------- | -------- | ------ |
| E1: `EXECVE curl`      | **프로세스·네트워크 실시간 차단/관찰** (`curl`·`wget` 비인가 호출 차단) | EDR 네트워크 컨트롤, eBPF/iptables 아웃바운드 제한(도메인 허용목록) | 대상 호스트   | 제안     |
| E2: `upgrade_geoip.sh` | **스크립트 무결성 검증**(SHA-256 생성 후 레퍼런스와 대조)            | 파일 무결성(FIM), 서명/해시 핀닝                          | 파일/경로 단위 | 제안     |
| E3: TI 연계 불명           | **DNS 해석 → 실제 접속 IP·ASN 검증**                      | DNS 로그, Passive DNS, `dig +short` 아카이브         | 도메인/URL  | 제안     |
| E4: 베이스라인              | **크론/시스템 타이머 점검**(정기 업데이트 여부)                     | `crontab -l`, `systemd list-timers`            | 호스트 전역   | 제안     |
| E5: 롤백 대비              | **다운로드 산출물 격리·분석 후 배포 롤백 플랜 준비**                  | 샌드박스/디컴파일, 배포도구 롤백                             | 서비스 영향범위 | 제안     |

---

## 추가 탐지/차단 룰 제안 (예: Sigma/정책 키워드 수준)

* **auditd(ExecVE) 키워드 룰(탐지)**

  * 조건: `a0 = "curl"` AND `a2 CONTAINS "/module/upgrade_geoip.sh"`
  * 추가: `UID != root` 또는 **비인가 사용자** 실행 시 **상향 경보**.
* **Sysmon/로그 정책(Windows 환경 참고용)**

  * Event ID 1(Process Create): `Image = *\curl.exe` AND `CommandLine CONTAINS "https://"` AND **사내 도메인 비허용 목록**.
* **네트워크/Egress 정책(차단/허용 목록)**

  * **허용 목록(allow-list)**: 공식 배포 도메인만 허용(`repo.plura[.]io`), **인증서 핀닝** 필수.
* **정책 키워드(간단)**: `curl`, `wget`, `http(s)://`, `upgrade_geoip.sh`, `plura`, `repo`
* **정상 허용(예외)**: 내부 문서화된 **정상 업데이트 윈도우**와 **SHA-256 레퍼런스** 일치 시 **노이즈 저감**.

---

## 원본 인용 (핵심 raw\_log 필드 일부)

```json
{
  "timegenerated": "2025-09-01T10:42:36.681968+09:00",
  "programname": "audispd",
  "hostname": "QA-WAF-Stg",
  "msg": "node=QA-WAF-Stg type=EXECVE msg=audit(1756690956.671:48536): argc=3 a0=\"curl\" a1=\"-s\" a2=\"https://repo.plura.io/v5/module/upgrade_geoip.sh\""
}
```

---

### 부록: 분석 메모

* **결정 포인트**: (1) `repo.plura.io`의 **소유/인증서/핀닝** 검증, (2) `upgrade_geoip.sh`의 **해시/변경 이력**, (3) **DNS 해석 결과**와 TI 수치 대상의 일치 여부.
* **판단 가이드**: 세 항목이 **정상**이면 **2단계(주의)** 로 하향, 하나라도 불일치/의심이면 **3단계(경계)** 유지 또는 **4단계(위기)** 고려.
