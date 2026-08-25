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
build="podman"
tag=$(date +"%Y%m%d")
HARBOR_LINK="harbor.test.slainte.at/test"
image="test/dummy"
${build} build --no-cache --force-rm . -t ${HARBOR_LINK}/${image}:${tag} -t ${HARBOR_LINK}/${image}:latest -f dockerfile
${build} push ${HARBOR_LINK}/${image}:${tag}
${build} push ${HARBOR_LINK}/${image}:latest
curl -k ${HARBOR_LINK}/v2/${image}/tags/list
#
