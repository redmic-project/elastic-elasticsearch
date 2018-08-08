#!/bin/bash

templateFilename="elasticsearch"
otherNodes=""

chown -R elasticsearch:elasticsearch ${ES_DATA_PATH}

if [ -n "${SWARM_MODE}" ]; then
    if [ -z "${SERVICE_NAME}" ]; then
        >&2 echo "Environment variable SERVICE_NAME not set. You MUST set it to name of docker swarm service"
        exit 3
    fi

    DISCOVERY_DELAY=${DISCOVERY_DELAY:-15}

    echo "Waiting ${DISCOVERY_DELAY}s before discovering..."

    # Delay to let hostname to be published to swarm DNS service
    sleep ${DISCOVERY_DELAY}

    echo "Discovering other nodes in cluster..."
    # Docker swarm's DNS resolves special hostname "tasks.<service_name" to IP addresses of all containers inside overlay network
    swarmServiceIps=$(dig tasks.${SERVICE_NAME} +short)
    echo "Nodes of service ${SERVICE_NAME}:"
    echo "${swarmServiceIps}"

    hostname=$(hostname)
    myIp=$(dig ${hostname} +short)
    echo "My IP: ${myIp}"


    for nodeIp in ${swarmServiceIps}
    do
        if [ "${nodeIp}" == "${myIp}" ];then
            continue;
        fi
        otherNodes="${otherNodes}${nodeIp},"
    done

    if [ -n "${myIp}" ];then
        echo "Setting network.publish_host=${myIp}"
        export ES_NETWORK_PUBLISH_HOST=${myIp}
    fi
fi

envsubst < /${templateFilename}.template > ${ES_PATH}/config/${templateFilename}.yml

# Search nodes
if [ -n "${otherNodes}" ];then
    echo "Setting discovery.zen.ping.unicast.hosts=${otherNodes%,}"
	export ES_DISCOVERY_ZEN_PING_UNICAST_HOSTS=${otherNodes%,}
	ES_DISCOVERY_ZEN_PING_UNICAST_HOSTS=",${ES_DISCOVERY_ZEN_PING_UNICAST_HOSTS}"
	echo "discovery.zen.ping.unicast.hosts: ${ES_DISCOVERY_ZEN_PING_UNICAST_HOSTS}" \
		| sed -e 's/,/\n   - /g' >> ${ES_PATH}/config/${templateFilename}.yml
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

    echo "cloud.aws.s3.access_key: ${AWS_ACCESS_KEY_ID}" >> ${ES_PATH}/config/${templateFilename}.yml
    echo "cloud.aws.s3.secret_key: ${AWS_SECRET_ACCESS_KEY}" >> ${ES_PATH}/config/${templateFilename}.yml
}


# Install plugins
pluginsInstalled=$(${ES_PATH}/bin/elasticsearch-plugin list)
IFS=';' read -ra PLUGINS <<< "${ES_PLUGINS}"
for plugin in "${PLUGINS[@]}"; do
    echo "Installing plugin ${plugin}"

    if [ "${plugin}" == "repository-s3" ]; then
        check_credentials_s3
    fi

    echo "${pluginsInstalled}" | grep "${plugin}"
    if [ "${?}" -ne "0" ]; then
        gosu elasticsearch ${ES_PATH}/bin/elasticsearch-plugin install --batch ${plugin}
    else
        echo "Plugin ${plugin} already installed!"
    fi
done

cat ${ES_PATH}/config/${templateFilename}.yml

/manage-users.sh & disown

gosu elasticsearch "$@"
