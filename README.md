# Elasticsearch

## Search Guard

### Certificates creation

Search Guard provides a tool, [Search Guard TLS Tool](https://search.maven.org/search?q=a:search-guard-tlstool). Download and extract it.

First, create a yaml file with certificates definition, at `config/example.yml` inside extracted content:

```
ca:
  root:
    dn: CN=root-ca.example.net,O=EXAMPLE
    keysize: 2048
    validityDays: 3650
    pkPassword: none
    file: root-ca.pem

defaults:
  validityDays: 3650
  pkPassword: none
  generatedPasswordLength: 12
  httpsEnabled: true
  reuseTransportCertificatesForHttp: true

nodes:
  - name: node1
    dn: CN=es1.example.net
    dns:
      - elasticsearch-1
      - es-1
  - name: node2
    dn: CN=es2.example.net
    dns:
      - elasticsearch-2
      - es-2
  - name: node3
    dn: CN=es3.example.net
    dns:
      - elasticsearch-3
      - es-3

clients:
  - name: admin
    dn: CN=admin.example.net
    admin: true
```

Then, use it with the script `tools/sgtlstool.sh` and generate the certificates:

```
$ ./sgtlstool.sh -c ../config/example.yml -v -ca
$ ./sgtlstool.sh -c ../config/example.yml -v -csr
$ ./sgtlstool.sh -c ../config/example.yml -v -crt -f -o
```

Your certificates will be generated inside `tools/out` directory.

### Configuration

Before using Search Guard, you must update the content of `/usr/share/elasticsearch/plugins/search-guard-6/sgconfig/sg_internal_users.yml` file, which define the users to be created and its roles.

You can generate the password hashes with a [online tool](https://8gwifi.org/bccrypt.jsp), for example.

```
admin_elastic:
  readonly: true
  hash: $2a...
  roles:
    - admin

kibanaserver:
  readonly: true
  hash: $2a...
```

### Initialization

When using Search Guard at first time, is required to run a script as certified admin, to create the configuration index.

While running, get into container and run the following commands:

```
$ cd /usr/share/elasticsearch/plugins/search-guard-6/tools

$ bash sgadmin.sh -cd /usr/share/elasticsearch/plugins/search-guard-6/sgconfig -icl \
	-key /usr/share/elasticsearch/config/certs/admin.key \
	-cert /usr/share/elasticsearch/config/certs/admin.pem \
	-cacert /usr/share/elasticsearch/config/certs/root-ca.pem \
	-nhnv -h localhost
```

## Snapshots

In order to create backups, you must configure a snapshot repository first. Run these command once inside running container:

```
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
