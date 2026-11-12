# HOWTO: `config/stats/dashboardLevel.json` DEV → STG → LIVE 배포

## 1. 목적 및 적용 범위

- **배포 대상:** `config/stats` 저장소의 루트 파일 `dashboardLevel.json` **1개**
- **원본(DEV):** `git@gitlab.plura.internal:config/stats.git` — `main`
- **대상(STG):** `git@s-gitops:config/stats.git` — `main`
- **대상(LIVE):** `git@gitops:config/stats.git` — `main`
- **순서:** DEV `main` → STG 승격 브랜치/MR → STG 검증 → LIVE 승격 브랜치/MR → LIVE 검증

> 제공된 `sync-filter-b1.md`의 저장소/환경 구분을 `config/stats`에 적용한 것입니다. `s-gitops` 및 `gitops` SSH 별칭과 실제 저장소 생성 여부는 작업 환경에서 확인해야 합니다.
>
> 참고 문서의 `--force-with-lease`는 저장소 전체 `main`을 초기화할 때 쓰는 명령입니다. **이번처럼 파일 1개를 배포할 때 사용하지 않습니다.** 다른 설정 파일과 Git 히스토리를 유지하기 위해 MR 기반으로 배포합니다.

## 2. 준비 확인

1. 세 저장소에서 `config/stats.git`에 접근 가능한지 확인합니다.
2. `main`은 보호 브랜치로 유지하고, 배포는 **MR 승인 후 병합**합니다.
3. `dashboardLevel.json`에 환경별로 달라야 할 설정값이 있는지 배포 전에 확인합니다.
4. 실제 설정 반영에 CI/CD, GitOps 동기화, 재시작/재적재가 필요한지는 각 환경 운영 정책을 확인합니다. **Git 병합 완료만으로 서비스 설정이 적용되었다고 간주하지 않습니다.**

## 3. DEV 최신 파일 확인

```bash
# 빈 작업 디렉터리에서 실행
git clone git@gitlab.plura.internal:config/stats.git stats-dev
cd stats-dev

git fetch origin main
git rev-parse origin/main
# JSON 문법 검증 (Python 3 필요)
python3 -m json.tool dashboardLevel.json > /dev/null
# 배포 원본 파일의 Git blob 해시 기록
git rev-parse origin/main:dashboardLevel.json
cd ..
```

## 4. DEV → STG 승격

```bash
git clone git@s-gitops:config/stats.git stats-stg
cd stats-stg

git fetch origin main
git remote add dev git@gitlab.plura.internal:config/stats.git
git fetch dev main

# 선택: STG 배포 전 기준 상태를 태그로 보존
TAG="backup-stg-stats-main-$(date +%Y%m%d-%H%M%S)"
git tag "$TAG" origin/main
git push origin "$TAG"

# STG 현재 main에서 MR용 새 브랜치 생성
REL="promote/dashboardLevel-$(date +%Y%m%d-%H%M%S)"
git switch -c "$REL" origin/main

# DEV main의 이 파일 하나만 반영
git restore --source=dev/main -- dashboardLevel.json

# 검증: JSON 유효성 및 변경 파일 확인
python3 -m json.tool dashboardLevel.json > /dev/null
git add dashboardLevel.json
git diff --cached --name-only
git diff --cached --check
git diff --cached -- dashboardLevel.json

# 변경이 있을 때만 커밋/푸시
git commit -m "chore(stats): promote dashboardLevel.json from dev to stg"
git push -u origin "$REL"
```

**이후 STG GitLab에서:** 위 `promote/dashboardLevel-*` 브랜치를 `main`으로 보내는 MR을 생성합니다. 변경 파일이 `dashboardLevel.json` 하나뿐인지 확인하고 승인·병합합니다. `git commit`이 `nothing to commit`이라고 표시되면 이미 같은 파일이므로 새 커밋은 필요하지 않습니다.

**STG MR 병합 후 검증**

```bash
git fetch origin main
# 두 blob 해시가 같아야 함
git rev-parse dev/main:dashboardLevel.json
git rev-parse origin/main:dashboardLevel.json
```

Git 해시 일치와 별개로 STG의 배포 파이프라인·실제 대시보드 동작을 확인한 뒤 LIVE로 진행합니다.

## 5. STG → LIVE 승격

> **DEV에서 LIVE로 바로 복사하지 않고, STG에서 검증 완료한 파일을 LIVE에 배포**합니다.

```bash
cd ..
git clone git@gitops:config/stats.git stats-live
cd stats-live

git fetch origin main
git remote add staging git@s-gitops:config/stats.git
git fetch staging main

# 선택: LIVE 배포 전 기준 상태 태그 보존
TAG="backup-live-stats-main-$(date +%Y%m%d-%H%M%S)"
git tag "$TAG" origin/main
git push origin "$TAG"

# LIVE 현재 main에서 MR용 새 브랜치 생성
REL="promote/dashboardLevel-$(date +%Y%m%d-%H%M%S)"
git switch -c "$REL" origin/main

# STG main에서 검증한 이 파일 하나만 반영
git restore --source=staging/main -- dashboardLevel.json

python3 -m json.tool dashboardLevel.json > /dev/null
git add dashboardLevel.json
git diff --cached --name-only
git diff --cached --check
git diff --cached -- dashboardLevel.json

git commit -m "chore(stats): promote dashboardLevel.json from stg to live"
git push -u origin "$REL"
```

**이후 LIVE GitLab에서:** 위 브랜치를 `main`으로 보내는 MR을 생성하여 승인·병합합니다. 적용 파이프라인과 운영 대시보드 결과를 확인합니다.

**LIVE MR 병합 후 검증**

```bash
git fetch origin main
# 두 blob 해시가 같아야 함
git rev-parse staging/main:dashboardLevel.json
git rev-parse origin/main:dashboardLevel.json
```

## 6. DEV / STG / LIVE 최종 비교

작업 루트 디렉터리에서 실행합니다.

```bash
git -C stats-dev fetch origin main
git -C stats-stg fetch origin main
git -C stats-live fetch origin main

echo "DEV : $(git -C stats-dev rev-parse origin/main:dashboardLevel.json)"
echo "STG : $(git -C stats-stg rev-parse origin/main:dashboardLevel.json)"
echo "LIVE: $(git -C stats-live rev-parse origin/main:dashboardLevel.json)"
```

세 파일 blob 해시가 동일하면 **해당 파일의 Git 내용이 동일함**을 확인한 것입니다. 저장소 전체 커밋 해시는 환경별로 달라도 정상입니다. 이후 각 환경에서 **실제 서비스 적용 여부**를 별도로 점검해야 합니다.

| No. | 확인 항목 | 완료 기준 |
| --- | --- | --- |
| 1 | DEV 파일 검증 | JSON 문법 정상, 원본 blob 해시 기록 |
| 2 | STG MR | 변경 파일 `dashboardLevel.json` 하나, 승인 및 병합 |
| 3 | STG 검증 | DEV/STG 파일 blob 해시 일치, 배포/동작 정상 |
| 4 | LIVE MR | 변경 파일 하나, 승인 및 병합 |
| 5 | LIVE 검증 | STG/LIVE 파일 blob 해시 일치, 배포/동작 정상 |
| 6 | 보호 정책 | 두 환경 모두 `main` 보호 유지, force push 미사용 |

## 7. 장애 시 복구

- GitLab에서 배포 MR의 **Revert** 기능을 사용하거나, 이전 `main` 버전의 `dashboardLevel.json`만 복원하는 별도 롤백 MR을 만듭니다.
- **`main`에 강제 푸시하지 않습니다.**
- 롤백 MR 병합 후 서비스 재적용/확인까지 진행합니다.

## 8. 적용 시 주의사항

- DEV 링크는 `dashboardLevel.json` 경로만 제공합니다. **실제 JSON 내용을 직접 조회·검토한 것은 아니므로** 특정 값이 STG/LIVE에 적합하다고 확인된 상태는 아닙니다.
- 저장소 전체를 통째로 DEV와 같게 맞추려는 작업이라면 절차가 달라집니다. 참고 문서의 초기 리셋 방식은 저장소 전체 히스토리를 바꾸므로 이번 단일 파일 배포에 적용하지 마세요.
