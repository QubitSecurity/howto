### 1. Hugo 다운로드 및 설치

#### 1.1 Hugo 디렉토리 지정 및 이동
````
cd /home/user
````
#### 1.2 Hugo 다운로드 및 설치
````
wget https://github.com/gohugoio/hugo/releases/download/v0.138.0/hugo_extended_0.138.0_Linux-64bit.tar.gz

tar -zxvf hugo_extended_0.138.0_Linux-64bit.tar.gz
````
#### 1.3 Hugo 사이트 디렉토리 생성
````
/home/user/hugo new site /home/user/blog
````

### 2. ananke 테마 다운로드 및 설치

#### 2.1 테마 적용 디렉토리 이동
````
cd /home/user/blog
````
#### 2.2 Git 초기화 및 테마 다운로드
````
git init

git submodule add https://github.com/budparr/gohugo-theme-ananke.git themes/ananke
````

### 3. Blog Git 연동

#### 3.1 Blog Git 디렉토리 이동
````
cd /home/user/blog/themes/ananke
````
#### 3.2 현재 Git 주소 확인 및 변경
````
git remote -v

git remote set-url origin https://github.com/qubitsec/blog.git

git remote -v
````
#### 3.3 Blog Git Push
````
git push -u origin main
````
#### 3.4 Blog Git Pull
````
git pull --autostash --rebase origin main
````
#### 3.5 Blog Git Pull 확인
````
cat /home/user/blog/themes/ananke/exampleSite/config.toml
````


### 4. Hugo 실행

#### 4.1 Hugo 실행 디렉토리 이동
````
cd /home/user/blog/themes/ananke/exampleSite
````
#### 4.2 Hugo 실행
````
nohup hugo server -b http://xxx.xxx.xxx.xxx -p 80 --bind 0.0.0.0 --disableFastRender -c /home/user/blog/themes/ananke/exampleSite/config.toml 1>/dev/null 2>&1 &
````
#### 4.2.1 Hugo 실행 예제
````
cd /usr/share/nginx/html/blog
nohup hugo server -b https://blog.plura.io -p 443 --bind 0.0.0.0 --disableFastRender > /var/log/hugo_server.log 2>&1 &
````
#### 4.3 Hugo 종료
````
pkill hugo
````
