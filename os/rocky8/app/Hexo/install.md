Hexo를 설치하는 방법은 간단하며, Node.js와 npm(Node Package Manager)이 필요합니다. 아래의 단계를 따라 Hexo를 설치하고 블로그를 생성해보세요.

### 1. **Node.js 및 npm 설치**
   - 먼저, Hexo를 사용하려면 Node.js와 npm이 필요합니다.
   - [Node.js 공식 사이트](https://nodejs.org/)에서 LTS 버전을 다운로드하여 설치합니다. Node.js를 설치하면 npm도 함께 설치됩니다.
   - 설치 완료 후, 터미널에서 다음 명령어로 Node.js와 npm이 제대로 설치되었는지 확인합니다:
     ```bash
     node -v
     npm -v
     ```

### 2. **Hexo 설치**
   - 터미널(또는 명령 프롬프트)에서 다음 명령어를 사용하여 Hexo를 전역으로 설치합니다:
     ```bash
     npm install -g hexo-cli
     ```
   - 설치가 완료되면 다음 명령어로 설치된 Hexo 버전을 확인할 수 있습니다:
     ```bash
     hexo -v
     ```

### 3. **블로그 생성**
   - Hexo를 설치한 후, 블로그를 생성하고자 하는 디렉토리로 이동합니다:
     ```bash
     cd path/to/your/blog-directory
     ```
   - 그런 다음, 아래 명령어를 사용하여 새로운 Hexo 블로그를 초기화합니다:
     ```bash
     hexo init my-blog
     cd my-blog
     npm install
     ```
   - `my-blog`은 생성할 블로그의 디렉토리 이름입니다. 원하는 이름으로 변경하여 사용할 수 있습니다.

### 4. **로컬 서버 실행**
   - 블로그를 생성한 디렉토리에서 아래 명령어를 사용하여 로컬 서버를 실행할 수 있습니다:
     ```bash
     hexo server
     ```
   - 그러면 기본적으로 `http://localhost:4000`에서 블로그를 확인할 수 있습니다.

### 5. **블로그 게시 및 배포**
   - 블로그를 배포하기 위해 `hexo generate` 명령어로 정적 파일을 생성하고, 원하는 호스팅 플랫폼에 업로드할 수 있습니다.
   - 기본적으로 Hexo는 GitHub Pages와 쉽게 연동할 수 있으며, `hexo deploy` 명령어로 배포할 수 있습니다.

### 6. **Mermaid 플러그인 설치 (선택 사항)**
   - Mermaid 다이어그램을 블로그에 추가하려면 `hexo-filter-mermaid-diagrams` 플러그인을 설치합니다:
     ```bash
     npm install hexo-filter-mermaid-diagrams --save
     ```
   - 그런 다음, Hexo의 설정 파일 `_config.yml`에 다음 내용을 추가합니다:
     ```yaml
     mermaid:
       enable: true
     ```
   - 이 설정으로 블로그 포스트에서 Mermaid 다이어그램을 사용할 수 있습니다.

이렇게 하면 Hexo를 설치하고 블로그를 생성할 수 있습니다. 이후 `source/_posts` 디렉토리에서 마크다운 파일로 글을 작성하면 됩니다.
