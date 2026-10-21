# MSA 개발 요청 — Go Sender v0.5

## 변경 범위

고객별 DB 설정은 MSA가 계속 관리합니다. MSA는 고객 서버에 직접 연결하지 않고
HAProxy의 TCP/514로 **RFC5424 + 라우팅 SD + 실제 이벤트 본문**을 보냅니다.
HAProxy/rsyslog는 원문을 넘기고, Go가 고객 목적지 및 출력 형식을 해석합니다.

내부 TCP 프레이밍은 `UTF-8 바이트 수 + 공백 + RFC5424 메시지`인 Octet-counting을 사용합니다.
길이에 그 길이 숫자나 구분 공백은 포함하지 않습니다. 문자 수로 계산하지 않습니다.

## 기존 v0.4 호환

```text
<134>1 2026-10-22T09:00:00+09:00 msa plura-relay - - [pluraRelay@32473 dst="172.16.12.212" port="514" proto="udp" framing="none"] hello
```

기존 메시지는 변경 없이 RFC5424로 출력됩니다. 고객별 별도 설정 파일이나 조회 API는 없습니다.

## 메타데이터 정의

| 항목 | 값 / 규칙 |
|---|---|
| APP-NAME | `plura-relay` 고정 |
| SD-ID | `pluraRelay@32473` 고정; 32473은 문서·PoC용 기업번호. 운영용 PEN은 별도 확정 |
| `dst` | 고객 수신 IP 문자열; 호스트명·URL·포트 혼합 금지 |
| `port` | `1`~`65535`, 10진 문자열, 앞자리 0 없음 |
| `proto` | `udp` 또는 `tcp` |
| `framing` | UDP `none`; TCP `octet-counting` 또는 `lf`. 생략 시 각각 기본값 적용 |
| `format` | `rfc5424`(기본), `rfc3164`, `cef` |
| `header` | CEF에만 허용: `rfc3164`(기본) 또는 `rfc5424` |
| MSG | 실제 일반 이벤트 본문 또는 MSA가 완성한 CEF 본문 |

대소문자를 구분합니다. 모르는 필드·중복 파라미터·중복 SD-ID는 거부됩니다.
빈 선택값을 `format=""`처럼 보내지 말고 생략하거나 정상 값을 넣습니다.
`proto="tls"`, `format="rfc5425"`는 미지원입니다.
RFC5424 헤더 timestamp는 RFC3339 형태, 소수초 최대 6자리이며 유효한 시각이어야 합니다.
Gateway의 8192바이트 입력 한도에는 헤더와 라우팅 SD까지 포함합니다.

## UI 매핑

| 화면 선택 | 전송 메타데이터 |
|---|---|
| RFC5424 | `format="rfc5424"` |
| RFC3164 | `format="rfc3164"` |
| CEF + BSD 헤더 수신기 | `format="cef" header="rfc3164"` |
| CEF + RFC5424 수신기 | `format="cef" header="rfc5424"` |
| RFC5425 | 미지원 안내; TLS 구현 전 활성화하지 않음 |

전송 프로토콜과 메시지 형식은 별도 필드입니다. 내부 전송은 항상 TCP/514지만 고객 전송은 UDP/TCP를 선택합니다.
CEF 헤더 선택은 수신 SIEM 파서 요구사항에 맞춰 결정합니다.

## CEF 본문 생성

예시(PLURA 매핑 정책의 초안이며 고객별 필드 정책 확정이 필요):

```text
CEF:0|QubitSecurity|PLURA-XDR|0.5|WAF-SQLI|SQL Injection detected|8|src=203.0.113.10 dst=192.0.2.20 act=blocked requestMethod=POST request=/login
```

제품 버전 필드는 실제 PLURA 제품 버전을 사용합니다. 위 `0.5`는 문서 예시이며 Go Relay 버전으로 제품 버전을 대체하라는 뜻이 아닙니다.
FilterID → Event Class ID, 필터명 → Name, 심각도 → Severity 매핑은 MSA가 수행합니다.
C/H/M/L을 10/8/5/2로 보낼지는 정책으로 확정해야 하며, Relay가 임의로 결정하지 않습니다.
CEF `dst`는 공격 대상 IP이고 라우팅 SD `dst`는 고객 Syslog 수신 서버 IP입니다.

이스케이프는 MSA에서 정확히 한 번 적용합니다.

- CEF 헤더 값: `\` → `\\`, `|` → `\|`.
- CEF 확장 값: `\` → `\\`, `=` → `\=`, 줄바꿈 → `\n`, CR → `\r`.
- CEF 전체: UTF-8. 필드 사이 구분자 `|`, key/value 구분자 `=` 자체는 이스케이프하지 않습니다.

예시의 SD를 JSON 안에 담는 경우 JSON 이스케이프와 CEF 이스케이프는 별개의 계층입니다.
Syslog의 실제 MSG에 JSON 따옴표/백슬래시를 중복해서 넣지 않도록 실제 바이트로 시험합니다.
Go는 기본 CEF 헤더와 이스케이프를 검증하고 그대로 전달하며, 확장 필드 사전과 SIEM 파서 호환성을 모두 판정하지 않습니다.

## 배포 순서와 시험

1. 두 Active Gateway 모두 v0.5를 설치하고 `/ready`가 200인지 확인합니다.
2. 기존 RFC5424 전송을 확인한 뒤 신규 `format` / `header`를 MSA에서 활성화합니다.
3. 고객 수신기로 RFC3164, CEF 두 헤더, TCP 두 프레이밍 및 UDP를 각각 시험합니다.

MSA는 여러 재사용 TCP 연결로 분산하며 한 연결 안의 메시지 프레임이 서로 섞이지 않게 직렬화합니다.
연결 오류 시 제한된 지수 백오프·재연결을 구현하고 무한 재시도로 업무 스레드를 막지 않습니다.
통신 상태의 표기는 '내부 전송 완료'와 '고객 수신 확인'을 구분합니다. 기본 Syslog에는 최종 저장 ACK가 없습니다.
순서·중복 제거가 중요한 경우 이벤트 ID를 본문/CEF에 포함하고 수신기와 합의합니다.

RFC3164는 연도·시간대·SD·PROCID·MSGID를 보존하지 않습니다. 필요한 정보는 MSA가 본문에 넣습니다.
legacy 기본 1024바이트와 내부 RFC5424 8192바이트 한도를 송신 전 확인합니다.
이번 단일 큐 PoC의 고객별 장애 격리/무손실 전송은 별도 설계 범위입니다.
