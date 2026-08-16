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

