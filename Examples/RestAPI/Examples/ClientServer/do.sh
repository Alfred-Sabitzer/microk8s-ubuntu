#!/bin/bash
############################################################################################
# Bauen und deployen
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition
# Please check for the right hostname
export docker_registry="registry.k8s.slainte.at"
# Bauen gegen das Ziel-Repository
tag=$(date +"%Y%m%d")
image="examples/clientserver"
# Deploy to real repo
podman build --no-cache --force-rm . -t ${docker_registry}/${image}:${tag} -t ${docker_registry}/${image}:latest
podman push ${docker_registry}/${image}:${tag}
podman push ${docker_registry}/${image}:latest
curl -k -s https://${docker_registry}/v2/${image}/tags/list
exit