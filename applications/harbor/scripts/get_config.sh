#!/bin/bash
############################################################################################
#
# Get configuration from Harbor API
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
shopt -o -s nounset #-No Variables without definition

get_specific_project() {
    project_name="$1"
    echo "Getting project: ${project_name}"
    curl --cert /etc/containers/certs.d/harbor.test.slainte.at/client.cert \
        --key /etc/containers/certs.d/harbor.test.slainte.at/client.key \
        --cacert /etc/containers/certs.d/harbor.test.slainte.at/ca.crt  \
        -k -X 'GET' \
        -u "admin:${HARBOR_ADMIN_PASSWORD}" \
        -H 'accept: application/json' \
        -H 'X-Is-Resource-Name: false' \
        "https://harbor.test.slainte.at/api/v2.0/projects/${project_name}" \
    >${project_name}.json 2>${project_name}.err 
}

get_project_members() {
    project_name="$1"
    echo "Getting project members: ${project_name}"
    curl --cert /etc/containers/certs.d/harbor.test.slainte.at/client.cert \
        --key /etc/containers/certs.d/harbor.test.slainte.at/client.key \
        --cacert /etc/containers/certs.d/harbor.test.slainte.at/ca.crt  \
        -k -X 'GET' \
        -u "admin:${HARBOR_ADMIN_PASSWORD}" \
        -H 'accept: application/json' \
        -H 'X-Is-Resource-Name: false' \
        "https://harbor.test.slainte.at/api/v2.0/projects/${project_name}/members?" \
    >${project_name}_members.json 2>${project_name}_members.err 
}

get_specific_user() {
    user_name="$1"
    echo "Getting user: ${user_name}"
    curl --cert /etc/containers/certs.d/harbor.test.slainte.at/client.cert \
        --key /etc/containers/certs.d/harbor.test.slainte.at/client.key \
        --cacert /etc/containers/certs.d/harbor.test.slainte.at/ca.crt  \
        -k -X 'GET' \
        -H 'accept: application/json' \
        -u "admin:${HARBOR_ADMIN_PASSWORD}" \
        "https://harbor.test.slainte.at/api/v2.0/users/search?&username=${user_name}" \
    >${user_name}.json 2>${user_name}.err
#
    user_id=$(cat ${user_name}.json | jq '.[] | .user_id')
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
    get_specific_project "test"
    get_specific_project "dockerhub"
    get_project_members "test"
    get_project_members "dockerhub"
    get_specific_user "developer"
    get_specific_user "maintainer"
}

main "$@"
