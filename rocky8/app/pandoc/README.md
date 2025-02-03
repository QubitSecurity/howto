# pandoc
> https://github.com/jgm/pandoc/blob/main/INSTALL.md
> https://downloads.haskell.org/~ghc/latest/


## 0. Pre request apps

```
dnf groupinstall "Development Tools"
```

## 1. Install

### 1.1 Download & Install

```
curl -sSL https://get.haskellstack.org/ | sh
```

```
stack install pandoc
```

```
export PATH=$HOME/.local/bin:$PATH
```

```
stack --version
```


### 1.2 Install Pandoc from source

```
wget https://github.com/jgm/pandoc/releases/download/3.6.2/pandoc-3.6.2-linux-arm64.tar.gz
```


```
stack setup
stack install
```

```
```

```
pandoc --version
```


## 2. Reinstall Tex Live

### 2.1 Remove old version

```
sudo dnf remove -y texlive texlive-*
sudo rm -rf /usr/local/texlive /usr/share/texlive /usr/bin/texlive /usr/bin/tlmgr
```

### 2.2 Check
- no need any print

```
which tlmgr
```

### 2.3 Install lastest version

```
wget https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
```

```
tar -xvf install-tl-unx.tar.gz
cd install-tl-*
```

```
sudo ./install-tl
```

### 3. Path

```
echo 'export PATH=/usr/local/texlive/bin/x86_64-linux:$PATH' >> ~/.bashrc
source ~/.bashrc
```

```
tlmgr --version
```

```
kpsewhich ucharcat.sty
```

### 3. Path

```
pandoc speech.md -o speech.pdf --pdf-engine=xelatex --from markdown+smart -V mainfont="Noto Sans CJK KR"
```


```
pandoc speech.md -o speech.pdf --pdf-engine=xelatex -V mainfont="NanumGothic"
```


```
fc-list :lang=ko
```


```

```




### X. Useful Links

> https://www.server-world.info/en/note?os=CentOS_Stream_8&p=mysql8&f=1


