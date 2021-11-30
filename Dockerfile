ARG PARENT_IMAGE_TAG="6.6.2"

FROM docker.elastic.co/elasticsearch/elasticsearch:${PARENT_IMAGE_TAG}

LABEL maintainer="info@redmic.es"

ARG ES_PATH="/usr/share/elasticsearch"

ENV ES_PATH="${ES_PATH}" \
	cluster.name="clustername" \
	node.name="nodename" \
	path.data="${ES_PATH}/data" \
	bootstrap.memory_lock="true"

ARG SEARCH_GUARD_VERSION="6.6.2-25.5"

RUN ulimit -n 65536 && \
	${ES_PATH}/bin/elasticsearch-plugin install --batch repository-s3 && \
	${ES_PATH}/bin/elasticsearch-plugin install --batch com.floragunn:search-guard-6:${SEARCH_GUARD_VERSION}

VOLUME [ "${ES_PATH}/data" ]
