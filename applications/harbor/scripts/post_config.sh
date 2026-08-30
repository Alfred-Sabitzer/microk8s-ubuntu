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
    member_user="${1}_members.json"
    echo "Posting project config: ${project_name} from file ${config_file} and members from file ${member_user}"

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
#
    # Loop over JSON-Objekts
    cat "$member_user" | jq -c '.[]' | while read -r item; do
        
        # Einzelne Werte aus dem aktuellen Objekt extrahieren
        entity_name=$(echo "$item" | jq -r '.entity_name')
        role_name=$(echo "$item" | jq -r '.role_name')

        cat <<EOF >${member_user}.json
{
  "member_user": {
    "username": "$entity_name"
  },
  "member_group": {
    "group_name": "$role_name"
  }
}
EOF
    curl --cert /etc/containers/certs.d/harbor.test.slainte.at/client.cert \
        --key /etc/containers/certs.d/harbor.test.slainte.at/client.key \
        --cacert /etc/containers/certs.d/harbor.test.slainte.at/ca.crt  \
        -k -X 'POST' \
        -u "admin:${HARBOR_ADMIN_PASSWORD}" \
        -H 'accept: application/json' \
        -H 'X-Resource-Name-In-Location: false' \
        -H 'Content-Type: application/json' \
        -d "@${member_user}.json" \
        "https://harbor.test.slainte.at/api/v2.0/projects/${project_name}/members"
#
    done
}

post_user_config() {
    user_name="$1"
    config_file="$2"
    echo "Posting user config: ${user_name} from file ${config_file}"

    email=$(cat ${config_file} | jq '.metadata.email')
    realname=$(cat ${config_file} | jq '.metadata.realname')
    comment=$(cat ${config_file} | jq '.metadata.comment')
    cat <<EOF >${config_file}.json
{
  "email": "${email}",
  "realname": "${realname}",
  "comment": "${comment}",
  "password": "${HARBOR_PASSWORD}",
  "username": "${user_name}",
}
EOF
    curl --cert /etc/containers/certs.d/harbor.test.slainte.at/client.cert \
        --key /etc/containers/certs.d/harbor.test.slainte.at/client.key \
        --cacert /etc/containers/certs.d/harbor.test.slainte.at/ca.crt  \
        -k -X 'POST' \
        -H 'accept: application/json' \
        -u "admin:${HARBOR_ADMIN_PASSWORD}" \
        -d "@${config_file}.json" \
        'https://harbor.test.slainte.at/api/v2.0/users' \
}

main() {
    post_user_config "developer" "developer_profile.json"
    post_project_config "test" "test_config.json"
    post_project_config "dockerhub" "dockerhub_config.json"
}

main "$@"
