#!/bin/bash
############################################################################################
#
# Post configuration to Harbor API
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
shopt -o -s nounset #-No Variables without definition

post_project_config() {
    project_name="$1"
    config_file="$2"
    echo "Posting project config: ${project_name} from file ${config_file}"

    metadata=$(cat ${config_file} | jq '.metadata')
    cve_allowlist=$(cat ${config_file} | jq '.cve_allowlist')
#
    cat <<EOF >${config_file}.json
{
  "project_name": "${project_name}",
  "metadata": ${metadata},
  "cve_allowlist": ${cve_allowlist},
  "storage_limit": 0
}
EOF
#
    curl --cert /etc/containers/certs.d/harbor.test.slainte.at/client.cert \
        --key /etc/containers/certs.d/harbor.test.slainte.at/client.key \
        --cacert /etc/containers/certs.d/harbor.test.slainte.at/ca.crt  \
        -k -X 'POST' \
        -u "admin:${HARBOR_ADMIN_PASSWORD}" \
        -H 'accept: application/json' \
        -H 'X-Resource-Name-In-Location: false' \
        -H 'Content-Type: application/json' \
        -d "@${config_file}.json" \
        'https://harbor.test.slainte.at/api/v2.0/projects'
}


post_user_config() {
    user_name="$1"
    config_file="$2"
    echo "Posting user config: ${user_name} from file ${config_file}"
    curl --cert /etc/containers/certs.d/harbor.test.slainte.at/client.cert \
        --key /etc/containers/certs.d/harbor.test.slainte.at/client.key \
        --cacert /etc/containers/certs.d/harbor.test.slainte.at/ca.crt  \
        -k -X 'POST' \
        -H 'accept: application/json' \
        -u "admin:${HARBOR_ADMIN_PASSWORD}" \
        -d "@${config_file}" \
        "https://harbor.test.slainte.at/api/v2.0/users/${user_id}" \
    >${user_name}_profile.json 2>${user_name}_profile.err 
#       
    curl --cert /etc/containers/certs.d/harbor.test.slainte.at/client.cert \
        --key /etc/containers/certs.d/harbor.test.slainte.at/client.key \
        --cacert /etc/containers/certs.d/harbor.test.slainte.at/ca.crt  \
        -k -X 'GET' \
        -H 'accept: application/json' \
        -u "admin:${HARBOR_ADMIN_PASSWORD}" \
        "https://harbor.test.slainte.at/api/v2.0/users/${user_id}" \
    >${user_name}_profile.json 2>${user_name}_profile.err 
}

main() {
    post_project_config "test" "test_config.json"
    post_project_config "dockerhub" "dockerhub_config.json"
    post_user_config "developer" "developer_config.json"
}

main "$@"
