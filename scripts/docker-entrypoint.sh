#!/bin/bash

templateFilename="elasticsearch"

chown -R elasticsearch:elasticsearch ${ES_DATA_PATH}

envsubst < /${templateFilename}.template > ${ES_PATH}/config/${templateFilename}.yml

function setS3Credentials() {

    if [ -z  "${AWS_ACCESS_KEY_ID}" ] || [ -z  "${AWS_SECRET_ACCESS_KEY}" ]
    then
        echo "ERROR! Variables AWS_ACCESS_KEY_ID and/or AWS_SECRET_ACCESS_KEY are empty"
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
        setS3Credentials
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
