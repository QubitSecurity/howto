웹 브라우저가 `Accept-Encoding: gzip`을 포함하여 요청하고,
Apache `mod_deflate`가 응답 본문을 gzip으로 압축하는 경우,
ModSecurity/에이전트가 수집하는 `Resp-body`가 압축 바이너리 상태로 전달되어
`(unsupported text encoding)`으로 표시될 수 있다.

이는 요청 기반 탐지·차단 실패라기보다는,
응답본문 증적 수집 및 응답본문 기반 분석의 제한 사항이다.

운영 환경에서는 전체 gzip 비활성화보다,
다음 중 하나를 권장한다.

1. Reverse proxy 구조에서는 `SecDisableBackendCompression On`으로 백엔드 압축을 제거하고,
   WAF 분석 후 프론트엔드에서 다시 압축한다.
2. Embedded Apache 구조에서는 `SetEnvIf` 또는 ModSecurity `setenv:no-gzip=1`을 이용해
   분석 대상 경로 또는 탐지 대상 요청에 한해 gzip을 비활성화한다.
3. 제품 측면에서는 에이전트가 `Content-Encoding: gzip` 응답을 binary-safe하게 수집한 뒤
   gzip 해제 후 분석·저장하는 기능을 별도 개선 항목으로 검토한다.
