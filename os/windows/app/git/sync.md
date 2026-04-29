
## System

```bash

sh ./api/d-git-sync.sh forensic-config
sleep 1

sh ./api/d-git-sync.sh system-vas
sleep 1

sh ./api/d-git-sync.sh system-mgmt
sleep 1

sh ./api/d-git-sync.sh system-control
sleep 1

sh ./api/d-git-sync.sh wdac
sleep 1

sh ./api/d-git-sync.sh diagram-category
sleep 1

```


```bash

sh ./api/s-git-sync.sh forensic-type
sleep 1

sh ./api/s-git-sync.sh forensic-config
sleep 1

sh ./api/s-git-sync.sh diagram-category
sleep 1

sh ./api/s-git-sync.sh system-mgmt
sleep 1

sh ./api/s-git-sync.sh system-control
sleep 1

sh ./api/s-git-sync.sh system-vas
sleep 1

sh ./api/s-git-sync.sh system-vasversion
sleep 1

sh ./api/s-git-sync.sh wdac
sleep 1

sh ./api/s-git-sync.sh log
sleep 1

sh ./api/s-git-sync.sh event
sleep 1

sh ./api/s-git-sync.sh data-name-mapping
sleep 1

```

```bash

sh ./api/git-sync.sh forensic-type
sleep 1

sh ./api/git-sync.sh forensic-config
sleep 1

sh ./api/git-sync.sh diagram-category
sleep 1

sh ./api/git-sync.sh system-mgmt
sleep 1

sh ./api/git-sync.sh system-control
sleep 1

sh ./api/git-sync.sh system-vas
sleep 1

sh ./api/git-sync.sh system-vasversion
sleep 1

sh ./api/git-sync.sh wdac
sleep 1

sh ./api/git-sync.sh log
sleep 1

sh ./api/git-sync.sh event
sleep 1

sh ./api/git-sync.sh data-name-mapping
sleep 1

```

---

## Filter


```bash

sh ./api/d-git-sync.sh filter-category
sleep 1

sh ./api/d-git-sync.sh filter-edr
sleep 1

sh ./api/d-git-sync.sh filter-mitre
sleep 1

sh ./api/d-git-sync.sh web-extends
sleep 1

sh ./api/d-git-sync.sh web-filter
sleep 1

```


```bash

sh ./api/s-git-sync.sh filter-category
sleep 1

sh ./api/s-git-sync.sh filter-edr
sleep 1

sh ./api/s-git-sync.sh filter-mitre
sleep 1

sh ./api/s-git-sync.sh web-extends
sleep 1

sh ./api/s-git-sync.sh web-filter
sleep 1

```

```bash

sh ./api/git-sync.sh filter-category
sleep 1

sh ./api/git-sync.sh filter-edr
sleep 1

sh ./api/git-sync.sh filter-mitre
sleep 1

sh ./api/git-sync.sh web-extends
sleep 1

sh ./api/git-sync.sh web-filter
sleep 1

```

---









---

## Repo

```bash

scp -r ./edr/ sysadmin@10.100.21.40:/home/sysadmin/repo/
sleep 1

scp -r ./edr/ sysadmin@10.100.21.41:/home/sysadmin/repo/
sleep 1

scp -r ./edr/ sysadmin@10.100.21.42:/home/sysadmin/repo/
sleep 1

scp -r ./edr/ sysadmin@10.100.21.43:/home/sysadmin/repo/
sleep 1

scp -r ./edr/ sysadmin@10.100.21.44:/home/sysadmin/repo/
sleep 1

scp -r ./edr/ sysadmin@10.100.21.45:/home/sysadmin/repo/
sleep 1

```



