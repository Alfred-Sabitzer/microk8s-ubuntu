#!/bin/bash
############################################################################################
#
# Install MicroK8s
# This script installs MicroK8s using the snap package manager.
# It checks the return code of the installation command and retries if it fails.
# It also sets up aliases for kubectl and runs a startup script.
#
############################################################################################
shopt -o -s nounset #-No Variables without definition

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

# Run the startup script
sudo ${indir}/MicroK8S_Start.sh

# Inspect MicroK8s installation
sudo microk8s inspect | sudo tee microk8s_inspect.log

# MicroK8s is installed and ready for use
# Please refer to the documentation for further instructions.