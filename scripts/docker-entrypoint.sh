#!/bin/bash

TEMPLATE_FILENAME="elasticsearch"
OTHER_NODES=""

chown -R elasticsearch:elasticsearch ${ES_DATA_PATH}

if [ -n "${SWARM_MODE}" ]; then
    if [ -z "${SERVICE_NAME}" ]; then
        >&2 echo "Environment variable SERVICE_NAME not set. You MUST set it to name of docker swarm service"
        exit 3
    fi

    # Delay to let hostname to be published to swarm DNS service
    sleep 15

    echo "Discovering other nodes in cluster..."
    # Docker swarm's DNS resolves special hostname "tasks.<service_name" to IP addresses of all containers inside overlay network
    SWARM_SERVICE_IPs=$(dig tasks.${SERVICE_NAME} +short)
    echo "Nodes of service ${SERVICE_NAME}:"
    echo "$SWARM_SERVICE_IPs"

    HOSTNAME=$(hostname)
    MY_IP=$(dig ${HOSTNAME} +short)
    echo "My IP: ${MY_IP}"


    for NODE_IP in $SWARM_SERVICE_IPs
    do
        if [ "${NODE_IP}" == "${MY_IP}" ];then
            continue;
        fi
        OTHER_NODES="${OTHER_NODES}${NODE_IP},"
    done

    if [ -n "${MY_IP}" ];then
        echo "Setting network.publish_host=${MY_IP}"
        export ES_NETWORK_PUBLISH_HOST=${MY_IP}
    fi
fi

envsubst < /${TEMPLATE_FILENAME}.template > ${ES_PATH}/config/${TEMPLATE_FILENAME}.yml

# Search nodes
if [ -n "${OTHER_NODES}" ];then
    echo "Setting discovery.zen.ping.unicast.hosts=${OTHER_NODES%,}"
	export ES_DISCOVERY_ZEN_PING_UNICAST_HOSTS=${OTHER_NODES%,}
	ES_DISCOVERY_ZEN_PING_UNICAST_HOSTS=",${ES_DISCOVERY_ZEN_PING_UNICAST_HOSTS}"
	echo "discovery.zen.ping.unicast.hosts: ${ES_DISCOVERY_ZEN_PING_UNICAST_HOSTS}" \
		| sed -e 's/,/\n   - /g' >> ${ES_PATH}/config/${TEMPLATE_FILENAME}.yml
else
    echo "There is no another nodes in cluster. I am alone!"
fi


function check_credentials_s3() {
    if [[ -z  "${AWS_ACCESS_KEY_ID}" ]]; then
        echo "ERROR! Variable AWS_ACCESS_KEY_ID is empty"
        VALUE=1
    fi

    if [[ -z  "${AWS_SECRET_ACCESS_KEY}" ]]; then
        echo "ERROR! Variable AWS_SECRET_ACCESS_KEY is empty"
        VALUE=1
    fi

    if [[ "$VALUE" == "1" ]]; then
        exit 1
    fi

    echo "cloud.aws.s3.access_key: ${AWS_ACCESS_KEY_ID}" >> ${ES_PATH}/config/${TEMPLATE_FILENAME}.yml
    echo "cloud.aws.s3.secret_key: ${AWS_SECRET_ACCESS_KEY}" >> ${ES_PATH}/config/${TEMPLATE_FILENAME}.yml
}


# Install plugins
pluginsInstalled=$(${ES_PATH}/bin/elasticsearch-plugin list)
IFS=';' read -ra PLUGINS <<< "${ES_PLUGINS}"
for PLUGIN in "${PLUGINS[@]}"; do
    echo "Installing plugin ${PLUGIN}"

    if [ "${PLUGIN}" == "repository-s3" ]; then
        check_credentials_s3
    fi

    echo "${pluginsInstalled}" | grep "${PLUGIN}"
    if [ "${?}" -ne "0" ]; then
        gosu elasticsearch ${ES_PATH}/bin/elasticsearch-plugin install --batch ${PLUGIN}
    else
        echo "Plugin ${PLUGIN} already installed!"
    fi
done

cat ${ES_PATH}/config/${TEMPLATE_FILENAME}.yml

./manage-users.sh & disown

gosu elasticsearch "$@"
