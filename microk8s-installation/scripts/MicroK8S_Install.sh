#!/bin/bash
############################################################################################
#
# Install MicroK8s
# This script installs MicroK8s using the snap package manager.
# It checks for successful installation, sets up aliases for kubectl,
# and calls another script to start MicroK8s while logging the inspection results.
#
############################################################################################
shopt -o -s nounset #- No Variables without definition

# Get the directory of the current script
indir=$(dirname "$0")

# Install MicroK8s
sudo snap install microk8s --classic --channel=latest/stable
rc=$?
echo "Return-code: ${rc}"

# Retry installation if it fails
while [ ${rc} -gt 0 ]; do
  sleep 30s
  sudo snap install microk8s --classic --channel=latest/stable
  rc=$?
  echo "Return code: ${rc}"
done

# Display tracking information
sudo snap info microk8s | grep -i tracking

# Set up kubectl alias
sudo snap unalias kubectl
sudo snap alias microk8s.kubectl kubectl

# Start MicroK8s
sudo "${indir}/MicroK8S_Start.sh"

# Log inspection results
sudo microk8s inspect | sudo tee microk8s_inspect.log

# MicroK8s is installed and ready for use
echo "MicroK8s installation completed successfully."