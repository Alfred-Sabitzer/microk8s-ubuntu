#!/bin/bash
############################################################################################
#
# MicroK8S holen der Login-Daten
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition
# Extrahieren der Login-Daten
rm -rf ~/.kube
mkdir -p ~/.kube
microk8s config > ~/.kube/config
#
# Jetzt funktioniert das lokal installierte kubectl
#
