#!/bin/bash
############################################################################################
#
# Configure UFW Firewall for MicroK8S
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition

indir=$(dirname "$0")

# You may need to configure your firewall to allow pod-to-pod and pod-to-internet communication:
sudo ufw --force reset
sudo ufw allow in on cni0 && sudo ufw allow out on cni0
sudo ufw default allow routed

# Enable Connections from our internal network
for ip in $(hostname --all-ip-addresses)
do
  sudo ufw allow from ${ip}/24
done

# For sure, we bring our own definitions
mkdir -p /etc/ufw/applications.d
sudo rm -f /etc/ufw/applications.d/*
cat ./../archive/ufw/ufw-profiles/applications.d/OpenSSH | sudo tee /etc/ufw/applications.d/OpenSSH
cat ./../archive/ufw/ufw-profiles/applications.d/Nginx | sudo tee /etc/ufw/applications.d/Nginx

sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'

sudo ufw --force enable
sudo ufw status verbose
#