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
HARBOR_LINK="harbor.test.slainte.at/test"
image="test/dummy"
# Build and push the image to Harbor
${build} login ${HARBOR_LINK} -u ${HARBOR_USER} -p ${HARBOR_PASSWORD}
# --network=host is needed becaus of lxd-container networking issues
${build} build --network=host --no-cache --force-rm . -t ${HARBOR_LINK}/${image}:${tag} -t ${HARBOR_LINK}/${image}:latest -f dockerfile
${build} push ${HARBOR_LINK}/${image}:${tag}
${build} push ${HARBOR_LINK}/${image}:latest
# sign the image with cosign
cosign sign --key cosign.key ${HARBOR_LINK}/${image}:${tag}
cosign sign --key cosign.key ${HARBOR_LINK}/${image}:latest
# list image tags
TOKEN=$(curl -sS \
  --cert /etc/containers/certs.d/harbor.test.slainte.at/client.cert \
  --key /etc/containers/certs.d/harbor.test.slainte.at/client.key \
  --cacert /etc/containers/certs.d/harbor.test.slainte.at/ca.crt \
  -u "${HARBOR_USER}:${HARBOR_PASSWORD}" \
  "https://harbor.test.slainte.at/service/token?service=harbor-registry&scope=registry:catalog:" \
  | jq -r '.token')
curl --cert /etc/containers/certs.d/harbor.test.slainte.at/client.cert \
 --key /etc/containers/certs.d/harbor.test.slainte.at/client.key \
 --cacert /etc/containers/certs.d/harbor.test.slainte.at/ca.crt  \
 -H "Authorization: Bearer $TOKEN" \
 -H "Accept: application/json" \
 -k https://harbor.test.slainte.at/v2/${image}/tags/list
#
curl --cert /etc/containers/certs.d/harbor.test.slainte.at/client.cert \
 --key /etc/containers/certs.d/harbor.test.slainte.at/client.key \
 --cacert /etc/containers/certs.d/harbor.test.slainte.at/ca.crt  \
 -H "Authorization: Bearer $TOKEN" \
 -H "Accept: application/json" \
 -k https://harbor.test.slainte.at/v2/test%2Ftest%2Fdummy/tags/list
#
curl --cert /etc/containers/certs.d/harbor.test.slainte.at/client.cert \
 --key /etc/containers/certs.d/harbor.test.slainte.at/client.key \
 --cacert /etc/containers/certs.d/harbor.test.slainte.at/ca.crt  \
 -H "Authorization: Bearer $TOKEN" \
 -H "Accept: application/json" \
 -k https://harbor.test.slainte.at/v2/test%2Ftest%2Fdummy/tags/list
