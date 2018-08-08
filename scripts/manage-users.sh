#!/bin/sh

elasticAdmin=elastic
retryManageUsers=1

while [ "${retryManageUsers}" -eq "1" ]
do
	responseStatus=$(curl --write-out %{http_code} --silent --output /dev/null \
		-u "${elasticAdmin}:${ELASTIC_ADMIN_PASS}" \
		"localhost:9200/_xpack/security/user/${elasticAdmin}")

	echo "Trying to manage users, got ${responseStatus} response"

	if [ "${responseStatus}" -eq "401" ] || [ "${responseStatus}" -eq "200" ]
	then
		retryManageUsers=0
	else
		sleep 1
		continue
	fi

	echo "Trying to update admin password"

	if [ "${responseStatus}" -eq "401" ]
	then
		curl -XPUT -u "${elasticAdmin}:${OLD_ELASTIC_ADMIN_PASS}" \
			"localhost:9200/_xpack/security/user/${elasticAdmin}/_password" \
			-H "Content-Type: application/json" -d "{
				\"password\": \"${ELASTIC_ADMIN_PASS}\"
			}"

		if [ "${?}" -eq "0" ]
		then
			echo "Admin password updated"
		fi
	else
		echo "Admin password already updated"
	fi

	echo "Trying to create default role and user"

	responseStatus=$(curl --write-out %{http_code} --silent --output /dev/null \
		-u "${elasticAdmin}:${ELASTIC_ADMIN_PASS}" \
		"localhost:9200/_xpack/security/role/${ELASTIC_USER_ROLE}")

	if [ "${responseStatus}" -eq "404" ]
	then
		curl -XPOST -u "${elasticAdmin}:${ELASTIC_ADMIN_PASS}" \
			"localhost:9200/_xpack/security/role/${ELASTIC_USER_ROLE}" \
			-H "Content-Type: application/json" -d '{
				"run_as": [],
				"cluster": [ "monitor" ],
				"indices": [{
					"names": [ "*" ],
					"privileges": [ "all" ]
				}]
			}'

		if [ "${?}" -eq "0" ]
		then
			echo "Role created"
		fi

		curl -XPOST -u "${elasticAdmin}:${ELASTIC_ADMIN_PASS}" \
			"localhost:9200/_xpack/security/user/${ELASTIC_USER}" \
			-H "Content-Type: application/json" -d "{
				\"password\": \"${ELASTIC_USER_PASS}\",
				\"roles\": [ \"${ELASTIC_USER_ROLE}\" ]
			}"

		if [ "${?}" -eq "0" ]
		then
			echo "User created"
		fi
	else
		echo "Default role already created, default user should has been created too"
	fi
done
