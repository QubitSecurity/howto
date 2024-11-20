# Ansible 디버깅 가이드

이 문서는 Ansible 플레이북이나 명령 실행 중 발생하는 문제를 디버깅하는 방법을 안내합니다.

---

## Ansible 그룹 연결 문제 디버깅

`solr-syslog` 그룹의 문제 있는 호스트를 식별하려면 아래 명령을 실행하세요:

```bash
ansible solr-syslog -i /home/pluraadmin/ansible/hosts -m ping --user=pluraadmin --private-key=/home/pluraadmin/.ssh/id_rsa 2>&1 | grep -E '(UNREACHABLE|FAILED)' > warn.log
```

### 설명:

1. **명령어 구성 요소**:
   - `ansible solr-syslog`: `solr-syslog` 그룹에서 Ansible 명령 실행.
   - `-i /home/pluraadmin/ansible/hosts`: 호스트 정의가 포함된 인벤토리 파일 지정.
   - `-m ping`: 각 호스트에 대한 연결 테스트를 수행하는 `ping` 모듈 사용.
   - `--user=pluraadmin`: SSH 접속 시 사용할 사용자 이름 지정 (`pluraadmin`).
   - `--private-key=/home/pluraadmin/.ssh/id_rsa`: 지정된 SSH 개인 키를 사용하여 인증.
   - `2>&1`: 표준 출력과 오류 출력을 동일한 스트림으로 리디렉션.
   - `| grep -E '(UNREACHABLE|FAILED)'`: 출력에서 `UNREACHABLE` 또는 `FAILED`로 표시된 호스트만 필터링.
   - `> warn.log`: 필터링된 결과를 `warn.log` 파일에 저장.

2. **예상 출력**:
   - `warn.log` 파일에는 연결이 불가능하거나 실패한 호스트가 기록됩니다:
     ```
     192.168.1.1 | UNREACHABLE! => {
         "changed": false,
         "msg": "Failed to connect to the host via ssh: Permission denied (publickey).",
         "unreachable": true
     }
     ```

---

## 연결 문제 해결 방법

1. **SSH 연결 확인**:
   - 문제가 발생한 호스트에 수동으로 SSH 연결을 테스트합니다:
     ```bash
     ssh -i /home/pluraadmin/.ssh/id_rsa pluraadmin@192.168.1.1
     ```

2. **인벤토리 파일 구문 확인**:
   - 인벤토리 파일(`/home/pluraadmin/ansible/hosts`)이 올바르게 작성되었는지 확인합니다. 예:
     ```ini
     [solr-syslog]
     192.168.1.1
     192.168.1.1
     ansible_user=pluraadmin
     ansible_ssh_private_key_file=/home/pluraadmin/.ssh/id_rsa
     ```

3. **호스트 도달 여부 확인**:
   - 호스트가 네트워크 상에서 접근 가능한지 확인합니다:
     ```bash
     ping 192.168.1.1
     ```

4. **로그 검토**:
   - `warn.log` 파일을 확인하여 오류 메시지를 분석하고 원인을 파악합니다.

---

## 추가 디버깅 옵션

자세한 디버깅 정보를 확인하려면 `-vvvv` 옵션을 추가합니다:
```bash
ansible solr-syslog -i /home/pluraadmin/ansible/hosts -m ping --user=pluraadmin --private-key=/home/pluraadmin/.ssh/id_rsa -vvvv
```

이 옵션은 Ansible 명령 실행의 모든 단계를 상세히 출력합니다.

---

## 추가 지원

문제가 해결되지 않을 경우, 스크립트에서 생성한 `debug.log` 파일을 검토하거나 시스템 관리자에게 문의하세요.
