ARG PARENT_IMAGE_TAG="6.5.1"

FROM docker.elastic.co/elasticsearch/elasticsearch:${PARENT_IMAGE_TAG}

LABEL maintainer="info@redmic.es"

ARG ES_PATH="/usr/share/elasticsearch"

ENV cluster.name="clustername" \
	node.name="nodename" \
	node.master="true" \
	node.data="true" \
	node.ingest="true" \
	path.data="${ES_PATH}/data" \
	network.host="0.0.0.0" \
	bootstrap.memory_lock="true" \
	indices.query.bool.max_clause_count="30000"

RUN ulimit -n 65536 \
	${ES_PATH}/bin/elasticsearch-plugin install --batch repository-s3

VOLUME [ "${ES_PATH}/data" ]
