Rocky Linux 8에서 블로그 전용 계정을 만드는 방법은 간단합니다. 이 계정을 통해 Hexo 블로그를 관리할 수 있습니다. 다음 단계에 따라 계정을 생성하고 필요한 권한을 설정해보세요.

### 1. **새 사용자 계정 생성**
   - 터미널에 로그인한 후 다음 명령어를 사용하여 새 사용자 계정을 생성합니다. 예를 들어, 계정 이름을 `bloguser`로 만든다면:
     ```bash
     sudo adduser bloguser
     ```
   - 생성한 사용자에게 암호를 설정합니다:
     ```bash
     sudo passwd bloguser
     ```
   - 프롬프트가 나타나면 새 비밀번호를 입력하고 확인합니다.

### 2. **블로그 디렉토리 준비 및 권한 설정**
   - 블로그 파일을 저장할 디렉토리를 생성하고 해당 디렉토리에 대한 권한을 새로 만든 계정에 부여합니다.
   - 예를 들어, 홈 디렉토리 내에 `hexo_blog`라는 디렉토리를 생성하려면 다음 명령을 사용합니다:
     ```bash
     sudo mkdir /home/bloguser/hexo_blog
     sudo chown -R bloguser:bloguser /home/bloguser/hexo_blog
     ```
   - 이 명령어는 `bloguser` 계정이 `hexo_blog` 디렉토리에 대한 소유권을 가지도록 설정합니다.

### 3. **Sudo 권한 설정 (선택 사항)**
   - 블로그 관리에 루트 권한이 필요한 경우(예: 소프트웨어 설치, 시스템 업데이트 등) 새 계정에 `sudo` 권한을 부여할 수 있습니다. 다만, 보안상 이유로 블로그 관리 계정에 sudo 권한을 부여하는 것은 주의가 필요합니다.
   - `bloguser` 계정에 `sudo` 권한을 추가하려면 다음 명령어를 사용합니다:
     ```bash
     sudo usermod -aG wheel bloguser
     ```

### 4. **블로그 계정으로 로그인**
   - 이제 새로 만든 계정으로 전환하거나 로그아웃 후 `bloguser`로 로그인할 수 있습니다:
     ```bash
     su - bloguser
     ```

### 5. **Hexo 설치 및 블로그 환경 설정**
   - 위에서 만든 `bloguser` 계정으로 로그인한 상태에서 Hexo 설치 및 블로그 환경을 설정하면 됩니다. Node.js, npm, Hexo를 해당 계정에서 설치하고 사용하면 계정이 분리된 환경에서 블로그를 운영할 수 있습니다.

   ```bash
   # Node.js 및 npm 설치 (예시)
   curl -sL https://rpm.nodesource.com/setup_16.x | sudo bash -
   sudo dnf install -y nodejs

   # Hexo 설치
   npm install -g hexo-cli

   # 블로그 초기화
   cd /home/bloguser/hexo_blog
   hexo init my-blog
   cd my-blog
   npm install
   ```

이제 Rocky Linux 8에서 블로그 전용 계정이 만들어졌으며, 이 계정으로 블로그 관련 작업을 안전하게 관리할 수 있습니다.
