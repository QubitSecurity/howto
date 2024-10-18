Hugo는 정적 사이트 생성기(Static Site Generator)로, 빠르고 간편하게 개인 웹사이트를 만들 수 있는 도구입니다. Hugo를 사용해 자신만의 도메인을 설정한 웹사이트를 만드는 절차는 다음과 같습니다.

### 1. Hugo 설치
먼저 Hugo를 설치해야 합니다. 각 운영체제에 따라 설치 방법이 다릅니다.

#### MacOS:
```bash
brew install hugo
```

#### Windows:
Hugo의 [릴리스 페이지](https://github.com/gohugoio/hugo/releases)에서 Windows 설치 파일을 다운로드하고 설치하세요.

#### Linux:
```bash
sudo apt install hugo
```

### 2. 새로운 Hugo 사이트 생성
터미널을 열고 Hugo 사이트를 생성할 폴더로 이동한 후, 새로운 사이트를 생성합니다.
```bash
hugo new site mywebsite
```
`mywebsite`는 원하는 폴더명으로 대체 가능합니다.

### 3. 테마 선택 및 설치
Hugo 사이트의 스타일을 결정할 테마를 선택합니다. [Hugo Themes](https://themes.gohugo.io/)에서 원하는 테마를 선택할 수 있습니다. 예를 들어, `ananke` 테마를 사용할 수 있습니다.

```bash
cd mywebsite
git init
git submodule add https://github.com/theNewDynamic/gohugo-theme-ananke.git themes/ananke
```

테마 설정을 완료하려면 `config.toml` 파일을 열고 테마를 지정합니다:
```toml
theme = "ananke"
```

### 4. 첫 번째 페이지 만들기
사이트에 첫 번째 페이지를 추가하려면 아래와 같이 명령어를 실행하세요:

```bash
hugo new posts/my-first-post.md
```

이 명령어는 `content/posts/my-first-post.md` 파일을 생성합니다. 이 파일을 열고 원하는 내용을 추가하세요.

### 5. 로컬에서 사이트 확인
웹사이트가 잘 만들어졌는지 로컬 서버에서 확인할 수 있습니다.

```bash
hugo server -D
```

브라우저에서 `http://localhost:1313`에 접속하여 사이트를 미리 확인할 수 있습니다.

### 6. 정적 사이트 빌드
모든 작업이 완료되면 정적 사이트 파일을 생성합니다:

```bash
hugo
```

생성된 파일들은 `public` 디렉터리 안에 저장됩니다. 이 파일들을 웹 서버에 업로드하면 됩니다.

### 7. 맞춤형 도메인 연결
웹사이트 파일을 호스팅할 서버를 선택한 후, 자신만의 도메인을 연결합니다. GitHub Pages, Netlify, Vercel 같은 정적 사이트 호스팅 서비스를 사용하면 손쉽게 도메인을 설정할 수 있습니다.

#### GitHub Pages 사용 예:
1. 사이트를 GitHub 저장소에 푸시합니다:
   ```bash
   git add .
   git commit -m "Deploy my Hugo site"
   git push origin main
   ```

2. GitHub Pages 설정에서 사이트를 배포할 브랜치를 설정합니다. `public` 폴더를 GitHub Pages로 배포하려면 Hugo에서 `public` 폴더를 `gh-pages` 브랜치로 푸시하는 설정을 추가하면 됩니다.

3. 자신의 도메인을 연결하려면 `A` 레코드나 `CNAME` 레코드를 자신의 DNS 제공자에서 설정하고 GitHub Pages에서 도메인 연결을 설정합니다.

#### Netlify 사용 예:
1. [Netlify](https://www.netlify.com/)에 가입하고 새 사이트를 배포합니다.
2. GitHub 저장소와 연결하여 자동으로 배포합니다.
3. Netlify 설정에서 도메인을 구매하거나 기존 도메인을 연결할 수 있습니다.

Netlify와 같은 서비스는 맞춤 도메인과 SSL(HTTPS)를 쉽게 설정해 줍니다.

이 과정을 통해 Hugo로 자신의 도메인을 가진 웹사이트를 만들 수 있습니다.
