#!/bin/bash
############################################################################################
# Bauen des Containers
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition
source ./var.sh
# Build container
podman build --no-cache --pull --force-rm -t ${docker_registry}/${image}:${tag} -t ${docker_registry}/${image}:latest . -f Dockerfile
exit