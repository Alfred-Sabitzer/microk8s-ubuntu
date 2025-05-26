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
image="examples/opengpg"
docker_registry="${registry_k8s}"

# Deploy to real repo
docker build --no-cache --force-rm . -t ${docker_registry}/${image}:${tag} -t ${docker_registry}/${image}:latest
docker push ${docker_registry}/${image}:${tag}
docker push ${docker_registry}/${image}:latest
curl -k -s https://${docker_registry}/v2/${image}/tags/list
exit
