## 🪟 SQL Server Audit 로깅 설정
SQL Server에서 **Event ID 24000번대** 로그가 **Windows 응용 프로그램(Application) 로그**에 남도록 설정하려면, **SQL Server Audit**(감사) 기능을 사용할 때 대상을 '**Application Log**'로 지정해야 합니다.

설정은 크게 두 단계로 나뉩니다.

1.  **감사(Audit) 생성:** 로그를 *어디에* 저장할지 설정 (여기서 Application Log 선택)
2.  **감사 사양(Audit Specification) 생성:** *무엇을* 감시할지 설정 (로그인 성공, 실패 등)

가장 편한 SSMS(SQL Server Management Studio)를 이용한 방법과 **T-SQL(쿼리)** 방법 두 가지를 설명해 드리겠습니다.

-----

### 방법 1: SSMS(GUI)를 이용한 설정 (추천)

**1단계: 감사(Audit) 개체 생성 (저장 위치 설정)**

1.  SSMS에서 해당 인스턴스에 접속합니다.

2.  **보안(Security)** 폴더를 펼칩니다.

3.  **감사(Audits)** 폴더를 우클릭하고 \*\*[새 감사(New Audit)...]\*\*를 선택합니다.

4.  설정 창이 뜨면 다음 내용을 변경합니다.

      * **감사 이름:** 원하는 이름을 입력합니다 (예: `Audit_To_AppLog`).
      * **감사 대상(Audit destination):** 여기서 반드시 \*\*[Application Log]\*\*를 선택해야 합니다.

5.  **확인**을 누릅니다. (아직 활성화하지 마세요)

**2단계: 서버 감사 사양(Server Audit Specification) 생성 (수집할 이벤트 설정)**

1.  **보안(Security)** -\> **서버 감사 사양(Server Audit Specifications)** 폴더를 우클릭하고 \*\*[새 서버 감사 사양(New Server Audit Specification)...]\*\*을 선택합니다.
2.  **이름**을 입력하고, **감사(Audit)** 드롭다운 메뉴에서 방금 만든 감사(`Audit_To_AppLog`)를 선택합니다.
3.  **작업(Actions)** 표에서 수집하고 싶은 이벤트를 추가합니다.
      * 이전에 질문하신 ID들이 남게 하려면 다음과 같은 그룹을 추가합니다:
          * `FAILED_LOGIN_GROUP` (로그인 실패)
          * `SUCCESSFUL_LOGIN_GROUP` (로그인 성공)
          * `DATABASE_CHANGE_GROUP` (데이터베이스 생성/삭제 등)
4.  **확인**을 누릅니다.

**3단계: 활성화 (Enable)**

1.  방금 만든 \*\*감사(Audits)\*\*와 **서버 감사 사양(Server Audit Specifications)** 아이콘을 보면 빨간색 `X` 표시(비활성 상태)가 있습니다.
2.  각각 우클릭하여 **[감사 사용(Enable Audit)]** 및 \*\*[서버 감사 사양 사용(Enable Server Audit Specification)]\*\*을 클릭합니다.

-----

### 방법 2: T-SQL 스크립트를 이용한 설정 (빠름)

쿼리 창을 열고 아래 스크립트를 실행하면 위와 똑같이 설정됩니다.

```sql
USE [master]
GO

-- 1. 감사(Audit) 생성: 대상을 APPLICATION_LOG로 지정
CREATE SERVER AUDIT [Audit_To_AppLog]
TO APPLICATION_LOG
WITH
(
    QUEUE_DELAY = 1000,
    ON_FAILURE = CONTINUE
)
GO

-- 2. 서버 감사 사양(Specification) 생성: 로그인 성공/실패 감시 예시
CREATE SERVER AUDIT SPECIFICATION [ServerAuditSpec_AppLog]
FOR SERVER AUDIT [Audit_To_AppLog]
ADD (FAILED_LOGIN_GROUP),
ADD (SUCCESSFUL_LOGIN_GROUP),
ADD (DATABASE_OBJECT_CHANGE_GROUP)
GO

-- 3. 감사 및 사양 활성화 (반드시 해야 작동함)
ALTER SERVER AUDIT [Audit_To_AppLog] WITH (STATE = ON)
GO

ALTER SERVER AUDIT SPECIFICATION [ServerAuditSpec_AppLog] WITH (STATE = ON)
GO
```

-----

### 설정 후 확인 방법

1.  SQL Server에서 로그인을 시도하거나(성공/실패), 테이블을 생성하는 등의 테스트 액션을 수행합니다.
2.  Windows에서 이벤트 뷰어(Event Viewer)를 실행합니다 (`eventvwr.msc`).
3.  `Windows 로그 > 응용 프로그램(Application)`을 클릭합니다.
4.  소스가 **MSSQLSERVER**인 로그 중 **Event ID 24000번대**가 기록되는지 확인합니다.

### 💡 주의사항 (필독)

  * **Application Log의 용량:** 윈도우 응용 프로그램 로그는 기본적으로 크기 제한이 있고, 꽉 차면 오래된 로그가 지워집니다(순환). 트래픽이 많은 서버에서 '로그인 성공'까지 다 남기면 **중요한 시스템 로그가 밀려날 수 있습니다.**
  * **성능:** 파일(File)에 기록하는 것보다 응용 프로그램 로그에 기록하는 것이 SQL Server 성능에 약간 더 부하를 줄 수 있습니다. 대량의 감사가 필요한 경우 **파일(File) 방식**을 권장합니다.
