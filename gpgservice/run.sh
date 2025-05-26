#!/bin/bash
############################################################################################
# Starten des Containers (local)
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition
source ./var.sh
#
chmod 755 ${PWD}/data
podman run --detach \
  --volume ${PWD}/data:/data \
  -p 8080:8080 \
  --name ${runname} \
  --replace \
  --hostname ${hostname} \
  --restart always ${image}:latest
#
sleep 5
podman export "$(podman ps | grep -i ${runname} | awk '{print $1 }')" | gzip >  ${runname}_${tag}.tar.gz
exit