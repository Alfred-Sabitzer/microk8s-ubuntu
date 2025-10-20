#!/bin/bash
############################################################################################
#
# add user to microk8s group
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
shopt -o -s nounset #- No Variables without definition

sudo usermod -a -G microk8s ${USER}
sudo chown -f -R ${USER} ~/.kube
#