# Go Sender v0.5.0 시험 결과

## 실행 환경

- 제작/시험: Linux amd64, Debian 13 컨테이너, Go 1.23.2.
- 소스 언어 선언: Go 1.22. 외부 Go 모듈 없음, CGO_ENABLED=0 실행파일 빌드.
- 사용자 서버의 Red Hat Go 1.26.7, Rocky Linux 9 rsyslog 8.2510.0에서 **이번 v0.5를 실행한 결과는 아닙니다**.
- ZIP에는 전체 소스를 제공합니다. 사용자의 승인된 컴파일러로 빌드하기 위해 사전 빌드 바이너리는 배포하지 않습니다.

## 실제 실행한 항목

| 시험 | 결과 / 증거 |
|---|---|
| 단위 테스트·하위 사례·퍼즈 seed 총 65개 | PASS, `test-evidence/unit.txt` |
| Go statement coverage | 68.2% (완전한 검증을 의미하지 않음) |
| go vet / 빌드 / 버전 확인 | PASS, `build.txt` |
| Go race detector | PASS, `race.txt` |
| RFC5424 Structured Data 파싱 퍼즈 | 약 79892회 입력, PASS, `fuzz.txt` |
| 실제 Go 프로세스 stdin/ACK ↔ 로컬 UDP·TCP 수신기 | PASS, `smoke.txt` |
| RFC3164 출력 + CEF/RFC3164 + CEF/RFC5424 | PASS, `smoke.txt` |
| 라우팅 SD 제거·UTF-8 바이트 길이·TCP 연결 재사용·LF 제한 | PASS, 단위/소켓 시험 |
| 미허용 목적지, 금지주소, 잘못된 포맷·CEF의 폐기 및 원문 미기록 | PASS |
| TCP 연결 실패 시 ERR 재시도 요청 | PASS, 로컬 연결 거절 시험 |
| Health 200/503, 처리 중단·복구·drain·Go 종료 | PASS, `health.txt` |
| 기존 HAProxy의 HTTP/1.0 200 응답 비교 규칙 | 실제 Go HTTP 응답에서 PASS |
| Bash 송신기의 RFC6587 길이·고객 UDP 선택 | PASS, `bash.txt` |
| 설치 시 설정 보존·백업·원자적 실행파일 교체·오류 시 중단 | 임시 DESTDIR에서 PASS, `install.txt` |
| Bash/Python 문법 | PASS, `syntax.txt` |

Health 시험의 TCP 수신/큐 부분은 테스트 어댑터입니다.
**실제 rsyslog 프로세스를 사용한 end-to-end 시험이라고 해석하면 안 됩니다.**
모든 네트워크 시험은 이 제작 환경의 loopback을 사용했고 고객 실서버로 송신하지 않았습니다.

## 기존 설정과의 정적 호환성 확인

앞서 제공된 `PLURA_XDR_Rsyslog_2files.zip`, `PLURA_XDR_HAProxy_2files.zip`을 확인했습니다.

- 실행 경로 `/usr/libexec/rsyslog/plura-syslog-sender` 유지.
- `-config /etc/plura-syslog/sender.json` 및 stdin JSON `app/raw/source` 유지.
- `confirmMessages=on`의 시작/메시지별 OK 또는 ERR 응답 유지.
- health APP-NAME `plura-health`, SD-ID `pluraHealth@32473`, 로컬 소켓 계약 유지.
- `-health -config /etc/plura-syslog/health.json`, `/ready`·`/live` 유지.
- TCP/514 데이터 수신과 HTTP/18081 상태 확인을 구분하는 구조 유지.
- 두 Gateway 모두 Active; 새 Go 코드에 주/대기 역할 없음.

이번 Go 패키지는 기존 HAProxy 및 rsyslog conf를 변경하지 않습니다.
실제 주소와 정책은 각 서버에서 서로 일치하도록 설정해야 합니다.

## 아직 실행하지 않은 검증

- 실제 HAProxy 3.2.x 설정 검사·두 Gateway Active-Active 분산·장애 제외·복귀.
- 실제 rsyslog 8.2510.0의 omprog와 v0.5 통합 실행.
- Rocky Linux 9/10 systemd·SELinux Enforcing·방화벽에서의 기동/송신.
- 고객 172.16.12.212 또는 외부 고객 SIEM의 CEF 파싱·저장.
- 초당 대량 로그, 장시간 처리, 고객별 장애 격리, 복구 시 순서/중복 정책.

기능/설치 시험이 운영 준비 완료를 뜻하지 않습니다. 현재 단일 메모리 큐 구조의
유실 가능성·장애 고객으로 인한 공통 큐 지연·상태 검사 연동은 README의 제한을 따릅니다.
