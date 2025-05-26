#!/bin/bash
############################################################################################
#
# Configure UFW Firewall for MicroK8S
#
############################################################################################
# This script configures the UFW firewall to allow necessary traffic for MicroK8s.
# It resets the firewall, allows pod-to-pod and pod-to-internet communication,
# and enables specific rules for OpenSSH and Nginx.
#
# Usage:
# Run this script with sudo privileges to configure the firewall for MicroK8s.
#
############################################################################################

shopt -o -s nounset #-No Variables without definition

# Reset the UFW firewall
sudo ufw --force reset

# Allow traffic on the CNI interface
sudo ufw allow in on cni0 && sudo ufw allow out on cni0
sudo ufw default allow routed

# Enable connections from the internal network
for ip in $(hostname --all-ip-addresses)
do
  sudo ufw allow from ${ip}/24
done

# Create necessary directories for UFW applications
mkdir -p /etc/ufw/applications.d
sudo rm -f /etc/ufw/applications.d/*

# Add OpenSSH and Nginx profiles to UFW
cat ./../archive/ufw/ufw-profiles/applications.d/OpenSSH | sudo tee /etc/ufw/applications.d/OpenSSH
cat ./../archive/ufw/ufw-profiles/applications.d/Nginx | sudo tee /etc/ufw/applications.d/Nginx

# Allow OpenSSH and Nginx traffic
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'

# Enable the UFW firewall
sudo ufw --force enable

# Display the status of UFW
sudo ufw status verbose
# End of script