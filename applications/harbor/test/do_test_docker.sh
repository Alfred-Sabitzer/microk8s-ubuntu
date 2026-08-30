#!/bin/bash
############################################################################################
#
# build and deploy against public Harbor test
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
shopt -o -s nounset #-No Variables without definition
# Build
build="docker"
tag=$(date +"%Y%m%d")
project="test"
image="dummy"
HARBOR_LINK="harbor.test.slainte.at"
# Build and push the image to Harbor
${build} login ${HARBOR_LINK} -u ${HARBOR_USER} -p ${HARBOR_PASSWORD}
# --network=host is needed becaus of lxd-container networking issues
${build} build --network=host --no-cache --force-rm . -t ${HARBOR_LINK}/${project}/${image}:${tag} -f dockerfile
${build} push ${HARBOR_LINK}/${project}/${image}:${tag}
# sign the image with cosign
digest=$(curl --cert /etc/containers/certs.d/harbor.test.slainte.at/client.cert \
    --key /etc/containers/certs.d/harbor.test.slainte.at/client.key \
    --cacert /etc/containers/certs.d/harbor.test.slainte.at/ca.crt  \
    -k -X 'GET' \
    -H 'accept: application/json' \
    -u "${HARBOR_USER}:${HARBOR_PASSWORD}" \
    https://${HARBOR_LINK}/api/v2.0/projects/${project}/repositories/${image}/artifacts? \
    | jq -r '.[] | .digest' 2>/dev/null)

export SSL_CERT_FILE="/etc/containers/certs.d/${HARBOR_LINK}/client.cert"
export SSL_KEY_FILE="/etc/containers/certs.d/${HARBOR_LINK}/client.key"
cosign sign --key cosign.key --allow-insecure-registry ${HARBOR_LINK}/${project}/${image}@${digest}
#