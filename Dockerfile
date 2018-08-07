ARG PARENT_IMAGE_NAME
ARG PARENT_IMAGE_TAG

FROM ${PARENT_IMAGE_NAME}:${PARENT_IMAGE_TAG}

ENV ES_CLUSTER_NAME="clustername" \
	ES_NODE_NAME="nodename" \
	ES_NODE_MASTER="true" \
	ES_NODE_DATA="true" \
	ES_NODE_INGEST="true" \
	ES_BOOTSTRAP_MEMORY_LOCK="true" \
	ES_INDICES_QUERY_BOOL_MAX_CLAUSE_COUNT=30000 \
	ES_NETWORK_HOST="0.0.0.0" \
	ES_NETWORK_BIND_HOST="0.0.0.0" \
	ES_NETWORK_PUBLISH_HOST="_eth0_" \
	ES_DISCOVERY_ZEN_MINIMUM_MASTER_NODES=2 \
	ES_PATH="/usr/share/elasticsearch"

ENV ES_DATA_PATH="${ES_PATH}/data"

RUN apt-get update && \
	apt-get install -y --no-install-recommends \
		gettext-base \
		dnsutils && \
	ulimit -n 65536

COPY config/ ${ES_PATH}/config/
COPY scripts/ /

VOLUME ["${ES_DATA_PATH}"]

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["elasticsearch"]
