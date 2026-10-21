# Elasticsearch

Elasticsearch is an open source distributed, RESTful search and analytics engine, scalable data store, and vector database

## Permission errors

At some environments, you may need to set ownership of the top-level directory at `elasticsearch-data-vol` volume.

Run a temporary container with volume mounted (repeat for each node) to set required ownership:

```sh
$ docker run --name elastic-ownership -it --rm -v elasticsearch-data-vol-X:/mnt alpine /bin/sh
> chown 1000 /mnt
> exit
```
