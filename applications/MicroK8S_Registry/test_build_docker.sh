#!/bin/bash
############################################################################################
#
# Test registry
# please consider https://microk8s.io/docs/registry-built-in
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
shopt -o -s nounset #-No Variables without definition

# Bauen gegen das Ziel-Repository
tag=$(date +"%Y%m%d")
image="tools/busybox"
docker_registry="${K8S_REGISTRY}"
podman build --no-cache --force-rm . -t ${docker_registry}/${image}:${tag} -t ${docker_registry}/${image}:latest
podman push ${docker_registry}/${image}:${tag}
podman push ${docker_registry}/${image}:latest
curl -k -s https://${docker_registry}/v2/${image}/tags/list
#
