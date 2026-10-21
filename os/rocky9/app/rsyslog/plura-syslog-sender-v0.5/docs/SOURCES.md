# 규격 및 구성 참고

이 패키지는 앞서 제공된 PLURA-XDR v0.4.1-ha Go 소스와 Active-Active 설치 자료를 수정한 것입니다.
버전 변경은 format.go, metadata.go, config.go, 설치·시험 스크립트, 문서에 반영했습니다.
기존 omprog 실행 경로·메시지 envelope·health 소켓/HTTP 계약은 유지합니다.

- rsyslog omprog: https://docs.rsyslog.com/doc/configuration/modules/omprog.html
- 처리 확인 응답: https://docs.rsyslog.com/doc/reference/parameters/omprog-confirmmessages.html
- stderr 로그: https://docs.rsyslog.com/doc/reference/parameters/omprog-output.html
- RFC5424 메시지/Structured Data: https://www.rfc-editor.org/rfc/rfc5424
- RFC3164 legacy 헤더/1024바이트 한도: https://www.rfc-editor.org/rfc/rfc3164
- RFC6587 TCP 프레이밍: https://www.rfc-editor.org/rfc/rfc6587
- ArcSight CEF 정의·헤더·이스케이프: https://www.microfocus.com/documentation/arcsight/arcsight-smartconnectors-8.3/cef-implementation-standard/Content/CEF/Chapter%201%20What%20is%20CEF.htm
- Go 설치: https://go.dev/doc/install

v0.5는 PLURA 메시지의 한정된 프로파일입니다. 모든 RFC의 모든 메시지, 모든 CEF 사전 필드,
각 SIEM의 독자 파서·프로토콜 확장 또는 제품 인증을 구현·보증한 것은 아닙니다.
TLS/RFC5425, 이중 큐 복제, exactly-once 및 고객별 장애 격리는 구현 범위 밖입니다.
