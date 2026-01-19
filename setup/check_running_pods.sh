#!/bin/bash
############################################################################################
#
# Überprüfung ob alle Pods bereit sind
#
############################################################################################
#shopt -o -s errexit #—Terminates the shell script if a command returns an error code.
shopt -o -s xtrace #—Displays each command before it is executed.
shopt -o -s nounset #-No Variables without definition
sleep 5
sudo microk8s kubectl wait --for=condition=ready --timeout=300s pod --all --all-namespaces || exit 1
#