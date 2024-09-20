## 1. Shard

### 1.1 syslog

```
http://10.10.11.40:8983/solr/admin/collections?action=CREATESHARD&shard=shard3&collection=weblog&createNodeSet=10.10.11.44:8983_solr


http://10.10.11.40:8983/solr/admin/collections?action=CREATESHARD&shard=shard4&collection=weblog&createNodeSet=10.10.11.46:8983_solr


http://10.10.11.40:8983/solr/admin/collections?action=CREATESHARD&shard=shard5&collection=weblog&createNodeSet=10.10.11.48:8983_solr

```

<hr/>

### 1.2 weblog

```
http://10.10.11.20:8983/solr/admin/collections?action=CREATESHARD&shard=shard3&collection=syslog&createNodeSet=10.10.11.24:8983_solr


http://10.10.11.20:8983/solr/admin/collections?action=CREATESHARD&shard=shard4&collection=syslog&createNodeSet=10.10.11.26:8983_solr


http://10.10.11.20:8983/solr/admin/collections?action=CREATESHARD&shard=shard5&collection=syslog&createNodeSet=10.10.11.28:8983_solr
```

<hr/>

### 1.3 resmonlog

```
http://10.10.63.160:8983/solr/admin/collections?action=CREATESHARD&shard=shard4&collection=resmonlog&0createNodeSet=10.10.63.170:8983_solr

http://10.10.63.160:8983/solr/admin/collections?action=CREATESHARD&shard=shard4&collection=resmonlog&0createNodeSet=10.10.63.172:8983_solr

http://10.10.63.160:8983/solr/admin/collections?action=CREATESHARD&shard=shard5&collection=resmonlog&createNodeSet=10.10.63.174:8983_solr
```
