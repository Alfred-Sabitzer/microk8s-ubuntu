############################################################################################
#
# sign the image with cosign - This script only works on the node where Harbor is running, because it needs to access the Harbor service via the clusterIP.
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
shopt -o -s nounset #-No Variables without definition
# Get service information from Harbor
export HARBOR_LINK=$(sudo microk8s kubectl get services -n harbor harbor -o jsonpath='{.spec.clusterIP}')
build="podman"
tag="20261114"
project="duplicity"
image="backup"
digest="sha256:3c9b8f81cf9e4d57e2e86a430ec1b0d04db484809c6954d52528e0de24a711ab"
# sign the image with cosign
export COSIGN_USER=$(sudo microk8s kubectl get secrets -n ${project} harbor-cosign -o jsonpath='{.data.username}' | base64 -d)
export HARBOR_PASSWORD=$(sudo microk8s kubectl get secrets -n ${project} harbor-cosign -o jsonpath='{.data.password}' | base64 -d)
export COSIGN_PASSWORD=$(sudo microk8s kubectl get secrets -n ${project} harbor-cosign -o jsonpath='{.data.cosign\.password}' | base64 -d)
export COSIGN_PRIVATE_KEY=$(sudo microk8s kubectl get secrets -n ${project} harbor-cosign -o jsonpath='{.data.cosign\.key}' | base64 -d)
export COSIGN_PUBLIC_KEY=$(sudo microk8s kubectl get secrets -n ${project} harbor-cosign -o jsonpath='{.data.cosign\.pub}' | base64 -d)
#
export DOCKER_CONFIG=$(mktemp -d)
cosign login ${HARBOR_LINK} --username=${COSIGN_USER} --password=${HARBOR_PASSWORD}
#
cosign sign --key <(echo "${COSIGN_PRIVATE_KEY}") --allow-insecure-registry  ${HARBOR_LINK}/${project}/${image}@${digest}
# Verifying with a public key variable
cosign verify --key <(echo "${COSIGN_PUBLIC_KEY}") --allow-insecure-registry  ${HARBOR_LINK}/${project}/${image}@${digest}
echo "Exit-Code: 0"
#
rm -rf "${DOCKER_CONFIG}"
unset COSIGN_USER
unset HARBOR_PASSWORD
unset COSIGN_PASSWORD
unset COSIGN_PRIVATE_KEY
unset COSIGN_PUBLIC_KEY
#
