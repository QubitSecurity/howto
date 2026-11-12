# HOWTO: config/stats 동기화 (dev → staging → live) — dashboardLevel.json

## 왜 하나
- 대시보드 카드 3개(계정·권한 변경 `accountchange`, C2 외부 통신 `c2`, AI·자동화 침투 `aipentest`)의 하단 게이지가 dev 에는 나오고 stg·live 에는 나오지 않는다.
- api/stats 는 카드 레벨 범위를 `config/stats` 의 `dashboardLevel.json` 에서 읽는다(git-sync 때 Redis `DASHBOARD_LEVEL` 로 올라감). 범위가 없는 카드는 `maxGauge = 0` 이 되고, 화면은 게이지를 숨긴다.
- 읽는 저장소가 환경마다 다르다.

  | 환경 | api/stats 가 읽는 저장소 (`application-*.yml` `git.repository`) |
  |---|---|
  | dev | `gitlab.plura.internal/config/stats` main — 3개 항목 있음(`7c8f21e` accountchange·c2, `8a3bd3a` aipentest) |
  | stg | `s-gitops.plura.internal/config/stats` main |
  | live | `gitops.plura.internal/config/stats` main |

- 그래서 dev 의 `dashboardLevel.json` 을 s-gitops·gitops 로 옮기고, 각 환경에서 git-sync 를 한 번 부르면 된다. FE·BE 코드 변경과 배포는 필요 없다.

> config/filter 동기화 문서(sync-filter)와 같은 흐름이다. 다만 **강제 push(`--force-with-lease`)와 main 리셋은 쓰지 않는다**(배포 정책 §7). 계보가 꼬여 있으면 아래 2-B 로 파일만 옮긴다.

---

## 0. 준비 (WSL, 처음 1회)

```bash
cd ~
git clone git@d-gitlab:config/stats.git stats      # 이미 있으면 생략
cd stats
git remote add s-gitops git@s-gitops:config/stats.git
git remote add gitops   git@gitops:config/stats.git
git remote -v                                       # origin=d-gitlab, s-gitops, gitops 세 개
```

매번 시작할 때:

```bash
cd ~/stats
git fetch origin && git fetch s-gitops && git fetch gitops
git log --oneline -3 origin/main                    # 맨 위가 8a3bd3a (aipentest 추가) 이어야 한다
```

---

## 1. 차이 확인 — 여기서 예상과 다르면 멈춘다

대상을 정하고(먼저 staging, 그다음 live) 같은 명령을 쓴다.

```bash
T=s-gitops        # live 단계에서는 T=gitops
```

### 1-1. 바뀌는 파일

```bash
git diff --stat $T/main origin/main
```

**예상:** `dashboardLevel.json` 한 파일만. `dashboardSection.json`·`dashboardCount.json` 등 다른 파일이 나오면 멈추고 공유한다(그 변경이 그 환경에 나가도 되는지 확인 필요).

### 1-2. dashboardLevel.json 의 실제 차이

```bash
git show $T/main:dashboardLevel.json   > /tmp/target.json
git show origin/main:dashboardLevel.json > /tmp/dev.json
python3 -c '
import json
t={x["serviceType"]:x["rangeList"] for x in json.load(open("/tmp/target.json"))}
d={x["serviceType"]:x["rangeList"] for x in json.load(open("/tmp/dev.json"))}
print("추가:", sorted(set(d)-set(t)))
print("삭제:", sorted(set(t)-set(d)))
print("값이 다름:", sorted(k for k in set(t)&set(d) if t[k]!=d[k]))
'
```

**예상:**
```
추가: ['accountchange', 'aipentest', 'c2']
삭제: []
값이 다름: []
```
- `삭제` 나 `값이 다름` 에 무엇이 나오면 멈춘다 — 그 환경 레벨 범위가 dev 와 다르게 운영 중이라는 뜻이라, 파일을 통째로 옮기면 다른 카드 색이 바뀐다.
- `추가` 가 비어 있으면 이미 반영된 것 → 3 단계(git-sync)만 하면 된다.

### 1-3. 계보 확인 (방법 고르기)

```bash
git merge-base --is-ancestor $T/main origin/main && echo "A: 같은 계보" || echo "B: 계보 다름"
```

---

## 2-A. 같은 계보일 때 — promote 브랜치 (sync-filter §3 표준)

```bash
REL="promote/$(date +%Y%m%d-%H%M%S)"
git push $T origin/main:refs/heads/$REL
```

→ 해당 GitLab(s-gitops 또는 gitops) 에서 `$REL` → `main` MR 생성 → 변경 파일이 `dashboardLevel.json` 하나인지 보고 Merge.

> live 단계는 sync-filter 표준대로 staging 을 거쳐도 된다: `git push gitops s-gitops/main:refs/heads/$REL` (단, 1-1·1-2 를 `origin/main` 대신 `s-gitops/main` 기준으로 다시 확인).

## 2-B. 계보가 다를 때 — 파일만 옮기는 커밋

대상 main 위에 dev 의 `dashboardLevel.json` 만 올린다. 대상의 다른 파일·이력은 건드리지 않는다.

```bash
REL="promote/$(date +%Y%m%d-%H%M%S)-dashboardLevel"
git switch -c "$REL" $T/main
git checkout origin/main -- dashboardLevel.json
git diff --cached --stat                            # dashboardLevel.json 1 파일, + 약 50줄
git commit -m "dashboardLevel: accountchange, c2, aipentest 추가 (dev 8a3bd3a 동기화)"
git push $T "$REL"
git switch main 2>/dev/null || git switch -
```

→ GitLab 에서 `$REL` → `main` MR → Merge.

### 확인

```bash
git fetch $T
git diff $T/main origin/main -- dashboardLevel.json   # 출력 없으면 동일
```

---

## 3. git-sync (환경마다 1번)

저장소에 넣기만 하면 화면은 바뀌지 않는다. api/stats 가 저장소를 다시 읽어 Redis 에 올려야 한다.

- API: **`POST /dashboard-level/git-sync`** (api/stats `DashboardLevelGitSyncController`, 게이트웨이 경로 `/stats/dashboard-level/git-sync`)
- filter git-sync 를 하던 곳(관리자 콘솔 / 담당자)에서 같은 방식으로 호출한다. 응답 `0000` 이면 완료.
- 순서: s-gitops MR 병합 → **stg git-sync** → 확인 → gitops MR 병합 → **live git-sync** → 확인.

---

## 4. 확인

1. s-xdr / xdr 대시보드 새로고침 → 계정·권한 변경, C2 외부 통신, AI·자동화 침투 카드 하단에 게이지 줄이 보인다.
2. (선택) 개발자 도구 Network 에서 `/stats/dashboard-agent/tag-cards` 응답의 세 카드 `maxGauge` 가 `20`(레벨 3 의 min)인지.
3. live 의 AI·자동화 침투처럼 위험도 4·5 탐지가 많은 카드는 아이콘 색(레벨)도 함께 바뀔 수 있다 — 범위가 생겨 레벨 계산이 시작되기 때문이며 정상이다.

---

## 하지 않는 것
- `git push --force` / `--force-with-lease`, main 리셋, protected branch 해제 — 계보가 꼬였으면 2-B 로 하고, 그래도 안 되면 멈추고 Simon 과 상의.
- `dashboardLevel.json` 을 GitLab 웹에서 손으로 고치기 — dev 파일과 어긋난다. 항상 dev 에서 옮긴다.

## 한 줄 요약
> dev `config/stats` 의 `dashboardLevel.json` 을 s-gitops → gitops 로 MR 로 옮기고, 각 환경 api/stats 에서 `POST /dashboard-level/git-sync` 를 부른다.
