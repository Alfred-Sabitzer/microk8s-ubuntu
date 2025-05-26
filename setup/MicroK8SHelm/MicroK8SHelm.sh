#!/bin/bash
############################################################################################
#
# MicroK8S Konfiguration Helm
#
# Infer repository core for addon helm3
# Helm comes pre-installed with MicroK8s
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition
# Erst disablen

microk8s disable helm3
# Helm enablen
microk8s status --wait-ready
microk8s enable helm3
#
# Logischer Link (kann für alle gut sein).
#
sudo snap unalias helm
sudo snap alias microk8s.helm3 helm
#
# Jetzt können wir Helm benutzen
#

