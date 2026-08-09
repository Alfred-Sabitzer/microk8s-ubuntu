#!/bin/bash
############################################################################################
#
# build and deploy
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
shopt -o -s nounset #-No Variables without definition
# Build
tag=$(date +"%Y%m%d")
podman login ${HARBOR_LINK} -u ${HARBOR_USER} -p ${HARBOR_PASSWORD}
image="test/dummy"
podman build --no-cache --force-rm . -t ${HARBOR_LINK}/${image}:${tag} -t ${HARBOR_LINK}/${image}:latest -f dockerfile
podman push ${HARBOR_LINK}/${image}:${tag}
podman push ${HARBOR_LINK}/${image}:latest
curl -u ${docker_username}:${docker_password} -k ${HARBOR_LINK}/v2/${image}/tags/list
#
