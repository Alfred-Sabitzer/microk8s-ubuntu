#!/bin/bash
############################################################################################
#
# Configure Harbor on MicroK8s.
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
shopt -o -s xtrace #—Displays each command before it is executed.
shopt -o -s nounset #-No Variables without definition

ADMIN_USER=admin
ADMIN_PASSWORD=${HARBOR_ADMIN_PASSWORD}
NAMESPACE=${NAMESPACE:-harbor}
KUBECTL_CMD=${KUBECTL_CMD:-kubectl}

username=$(${KUBECTL_CMD} get secrets -n $NAMESPACE harbor-development-user -o json | jq .data.username | sed 's/"//g' | base64 -d)
password=$(${KUBECTL_CMD} get secrets -n $NAMESPACE harbor-development-user -o json | jq .data.password | sed 's/"//g' | base64 -d)
url=$(${KUBECTL_CMD} get secrets -n $NAMESPACE harbor-development-user -o json | jq .data.url | sed 's/"//g' | base64 -d)
notes=$(${KUBECTL_CMD} get secrets -n $NAMESPACE harbor-development-user -o json | jq .data.notes | sed 's/"//g' | base64 -d)
comment=$(${KUBECTL_CMD} get secrets -n $NAMESPACE harbor-development-user -o json | jq .data.comment | sed 's/"//g' | base64 -d)
email=$(${KUBECTL_CMD} get secrets -n $NAMESPACE harbor-development-user -o json | jq .data.email | sed 's/"//g' | base64 -d)
realname=$(${KUBECTL_CMD} get secrets -n $NAMESPACE harbor-development-user -o json | jq .data.realname | sed 's/"//g' | base64 -d)

TOKEN=$(curl -sS \
  --cert /etc/containers/certs.d/harbor.test.slainte.at/client.cert \
  --key /etc/containers/certs.d/harbor.test.slainte.at/client.key \
  --cacert /etc/containers/certs.d/harbor.test.slainte.at/ca.crt \
  -u "${ADMIN_USER}:${ADMIN_PASSWORD}" \
  "https://harbor.test.slainte.at/service/token?service=harbor-registry&scope=registry:catalog:" \
  | jq -r '.token')

https://oneuptime.com/blog/post/2026-03-20-rancher-harbor-setup/view


Create a project in harbor

curl -u admin:Harbor12345 -X POST \
  -H "Content-Type: application/json" \
  http://192.168.0.103/api/v2.0/projects \
  -d '{"project_name": "dev", "public": true}'


  curl http://192.168.0.103/api/v2.0/projects/dev

  function create_project() {
  project_name=$1
  URL=$2
  PASSWORD=$3

  code=$(curl -s -o /dev/null -w "%{http_code}" -u "admin:$PASSWORD" -X HEAD $URL/api/v2.0/projects?project_name=${project_name})
  if [[ "$code" -eq 404 ]]; then
    # create project
    code=$(jq '.project_name = "'${project_name}'"' project_template.json | curl -s -o /tmp/result -w "%{http_code}" -u "admin:$PASSWORD" -H 'accept: application/json' -H 'Content-Type: application/json' --data-binary @- -X POST $URL/api/v2.0/projects)
    if [[ "$code" -eq 201 ]]; then
      echo "Created ${project_name} project"
    else
      echo "Failed to create ${project_name} project: HTTP code: $code"
      cat /tmp/result
      rm /tmp/result
    fi
  fi
}

# Usage
create_project my_project harbor.myurl.com 'mypassword'

{
    "project_name": "string",
    "public": true,
    "metadata": {
      "public": "true",
      "enable_content_trust": "false",
      "enable_content_trust_cosign": "false"
    },
    "storage_limit": 0
  }