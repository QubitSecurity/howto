
```bash

sh ./api/d-git-sync.sh forensic-config
sleep 1

sh ./api/d-git-sync.sh system-mgmt
sleep 1

sh ./api/d-git-sync.sh system-vas
sleep 1

sh ./api/d-git-sync.sh system-control
sleep 1

```


```bash

sh ./api/s-git-sync.sh forensic-config
sleep 1

sh ./api/s-git-sync.sh system-mgmt
sleep 1

sh ./api/s-git-sync.sh system-vas
sleep 1

sh ./api/s-git-sync.sh system-control
sleep 1

```

```bash

sh ./api/git-sync.sh forensic-config
sleep 1

sh ./api/git-sync.sh system-mgmt
sleep 1

sh ./api/git-sync.sh system-vas
sleep 1

sh ./api/git-sync.sh system-control
sleep 1

```

---

```bash

sh ./api/d-git-sync.sh filter-global
sleep 1

sh ./api/d-git-sync.sh filter-category
sleep 1

```


```bash

sh ./api/s-git-sync.sh filter-global
sleep 1

sh ./api/s-git-sync.sh filter-category
sleep 1

```

```bash

sh ./api/git-sync.sh filter-global
sleep 1

sh ./api/git-sync.sh filter-category
sleep 1

```




