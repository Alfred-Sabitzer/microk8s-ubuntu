#!/bin/bash
############################################################################################
# Bauen und deployen
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition
# Please check for the right hostname
export registry_k8s="registry.k8s.slainte.at"
# Bauen gegen das Ziel-Repository
tag=$(date +"%Y%m%d")
image="test/helloworld"
podman_registry="${registry_k8s}"
podman build --no-cache --force-rm . -t ${podman_registry}/${image}:${tag} -t ${podman_registry}/${image}:latest
podman push ${podman_registry}/${image}:${tag}
podman push ${podman_registry}/${image}:latest
curl -k -s https://${podman_registry}/v2/${image}/tags/list
#
