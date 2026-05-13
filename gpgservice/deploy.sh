#!/bin/bash
############################################################################################
# Bauen des Containers
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition
source ./var.sh
# Deploy to real repo
podman push ${docker_registry}/${image}:${tag}
podman push ${docker_registry}/${image}:latest
curl -k -s https://${docker_registry}/v2/${image}/tags/list
exit