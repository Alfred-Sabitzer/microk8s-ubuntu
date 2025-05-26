#!/bin/bash
############################################################################################
#
# Fast Installation microk8s
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition
# Systemupdate
sudo timedatectl set-timezone Europe/Vienna
date
sudo apt-get update
sudo apt-get upgrade -y
# Installation der notwendigen Software
sudo apt-get -y install open-iscsi
sudo systemctl enable iscsid
sudo systemctl start iscsid
sudo systemctl status iscsid
sudo apt-get install -y mc sshfs tree
sudo apt-get install bash-completion -y
# https://longhorn.io/docs/1.1.1/deploy/install/
sudo apt-get install curl util-linux jq nfs-common -y

# Remove MicroK8s
sudo microk8s stop
sudo microk8s status --wait-ready
sudo snap remove microk8s --purge
#