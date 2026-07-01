---

# 1. 소스 디렉터리로 이동

예를 들어 HAProxy 소스를 `/usr/local/src/haproxy-3.2.20`에 풀었다면

```bash
cd /usr/local/src/haproxy-3.2.20
```

---

# 2. http_fetch.c 백업

항상 원본은 백업해 두는 것이 좋습니다.

```bash
cp src/http_fetch.c src/http_fetch.c.bak
```

---

# 3. smp_fetch_allhdr() 함수 추가

## 먼저 함수 위치 찾기

`http_fetch.c`에서

```c
static int smp_fetch_hdr(
```

를 찾습니다.

보통

```bash
grep -n "static int smp_fetch_hdr" src/http_fetch.c
```

예를 들면

```
512: static int smp_fetch_hdr(...)
```

처럼 나옵니다.

---

## 어디에 넣나요?

가장 좋은 위치는

```
smp_fetch_hdr()

↓

smp_fetch_hdr_cnt()

↓

smp_fetch_hdr_names()
```

와 같은 **Header 관련 Fetch 함수들 근처**입니다.

예를 들면

```c
static int smp_fetch_hdr(...)
{
...
}
```

함수가 끝나는

```c
}
```

바로 아래에

새 함수를 붙여 넣습니다.

---

# 4. 함수 전문

아래 전체를 그대로 추가합니다.

```c
static int smp_fetch_allhdr(const struct arg *args,
                            struct sample *smp,
                            const char *kw,
                            void *private)
{
    struct channel *chn =
        ((kw[2] == 'q') ? SMP_REQ_CHN(smp) : SMP_RES_CHN(smp));

    struct check *check =
        ((kw[2] == 's') ? objt_check(smp->sess->origin) : NULL);

    struct htx *htx = smp_prefetch_htx(smp, chn, check, 1);

    struct http_hdr_ctx ctx;
    struct buffer *trash;
    struct ist name;
    char delim = ',';

    if (!htx)
        return 0;

    if (args[0].type != ARGT_STR)
        return 0;

    if (args[1].type == ARGT_STR)
        delim = *args[1].data.str.area;

    name = ist2(args[0].data.str.area,
                args[0].data.str.data);

    trash = get_trash_chunk();

    ctx.blk = NULL;

    while (http_find_header(htx, name, &ctx, 0)) {

        if (trash->data)
            trash->area[trash->data++] = delim;

        if (!chunk_memcat(trash,
                          ctx.value.ptr,
                          ctx.value.len))
            return 0;
    }

    smp->flags |= SMP_F_VOL_HDR;
    smp->data.type = SMP_T_STR;
    smp->data.u.str = *trash;

    return trash->data != 0;
}
```

---

# 5. Fetch 등록

이제

```bash
grep -n "req.hdr" src/http_fetch.c
```

를 실행합니다.

보통 아래와 비슷한 테이블이 있습니다.

```c
{ "req.hdr", ... },

{ "req.fhdr", ... },

{ "req.hdr_cnt", ... },
```

---

## req.allhdr 추가

`req.hdr` 바로 아래에

```c
{ "req.allhdr", smp_fetch_allhdr,    ARG2(1,STR,STR),    NULL,    SMP_T_STR,    SMP_USE_HRQHV },
```

추가합니다.

---

## response도 만들 경우

```c
{ "res.allhdr", smp_fetch_allhdr,    ARG2(1,STR,STR),    NULL,    SMP_T_STR,    SMP_USE_HRSHV },
```

도 추가합니다.

---

# 6. http_fetch.h 수정?

필요 없습니다.

왜냐하면

```c
static int smp_fetch_allhdr(...)
```

이므로

외부에서 참조하지 않습니다.

---

# 7. 컴파일

```bash
make clean

make TARGET=linux-glibc
```

또는 기존 옵션으로

```bash
make \
TARGET=linux-glibc \
USE_OPENSSL=1 \
USE_PCRE2=1 \
USE_ZLIB=1 \
...
```

---

# 8. 설치

```bash
cp haproxy /usr/sbin/haproxy
```

또는

```bash
make install
```

---

# 9. 설정파일 사용

이제

```haproxy
frontend http

    http-request set-var(txn.xff) \
        req.allhdr(X-Forwarded-For)

    http-request set-header X-Forwarded-For %[var(txn.xff)]
```

중복 헤더가

```
X-Forwarded-For: 1.1.1.1
X-Forwarded-For: 2.2.2.2
```

↓

```
1.1.1.1,2.2.2.2
```

로 반환됩니다.

---
