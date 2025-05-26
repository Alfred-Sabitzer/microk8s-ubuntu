#!/bin/bash
############################################################################################
#
# Stop microk8s
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition

sudo microk8s stop
rc=$?
echo "Returncode: ${rc}"

while  [ ${rc} -gt 0 ]
do
  sleep 30s
  sudo microk8s status --wait-ready
  rc=$?
  echo "Returncode: ${rc}"
done
#
# Jetzt ist microk8s gestoppt
#


