#!/bin/bash
############################################################################################
# Test podman pull and push to Harbor, inside a Kubernetes pod/container.
# Usage: ./test_podman.sh
############################################################################################
set -euo pipefail

# Ubuntu 20.10 and newer
apt-get update
apt-get -y install podman jq nano curl iputils-ping
#
cat << EOF | tee --append /etc/hosts
10.242.64.201   harbor.test.slainte.at
EOF

export HARBOR_USER=$(cat /tmp/secrets/robot-test-k8s/.dockerconfigjson | jq -r '.auths["harbor.test.slainte.at"] | "\(.username)"')
export HARBOR_PASSWORD=$(cat /tmp/secrets/robot-test-k8s/.dockerconfigjson | jq -r '.auths["harbor.test.slainte.at"] | "\(.password)"')
#
podman ps
#
podman login harbor.test.slainte.at -u ${HARBOR_USER} -p ${HARBOR_PASSWORD}
