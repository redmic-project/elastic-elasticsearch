# Elasticsearch

Elasticsearch is an open source distributed, RESTful search and analytics engine, scalable data store, and vector database

## Snapshots

In order to create backups, you must configure a snapshot repository first. Run these command once inside running container:

```sh
$ echo "${S3_ACCESS_KEY}" | elasticsearch-keystore add --stdin s3.client.default.access_key
$ echo "${S3_SECRET_KEY}" | elasticsearch-keystore add --stdin s3.client.default.secret_key

$ curl -XPOST -u <user>:<pass> 'http://localhost:9200/_nodes/reload_secure_settings'
// This can be run through Kibana console:
// POST _nodes/reload_secure_settings

$ curl -XPUT -u <user>:<pass> 'http://localhost:9200/_snapshot/s3-backup' -d '{
  "type": "s3",
  "settings": {
    "bucket": "redmic.elasticsearch.backup",
    "region": "eu-west-1"
  }
}'
// This can be run through Kibana console:
// PUT _snapshot/s3-backup { ... }
```
