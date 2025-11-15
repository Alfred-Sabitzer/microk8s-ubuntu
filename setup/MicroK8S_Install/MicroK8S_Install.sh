#!/bin/bash
############################################################################################
#
# Install MicroK8s
# This script installs MicroK8s using the snap package manager.
# It checks for successful installation, sets up aliases for kubectl,
# and calls another script to start MicroK8s while logging the inspection results.
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
shopt -o -s nounset #- No Variables without definition

# Get the directory of the current script
indir=$(dirname "$0")

# See https://microk8s.io/docs/release-notes
myversion="1.33/stable"

# Install MicroK8s
sudo snap install microk8s --classic --channel=${myversion}
rc=$?
echo "Return-code: ${rc}"

# Retry installation if it fails
while [ ${rc} -gt 0 ]; do
  sleep 30s
  sudo snap install microk8s --classic --channel=${myversion}
  rc=$?
  echo "Return code: ${rc}"
done

# Display tracking information
sudo snap info microk8s | grep -i tracking

# Set up kubectl alias
sudo snap unalias kubectl
sudo snap alias microk8s.kubectl kubectl

# Change cluster name in config files
for n in /var/snap/microk8s/current/credentials/*.config;
do
  echo "Changing Clustername to ${K8S_ENVIRONMENT}-cluster in file: $n"
  sed -i "s/microk8s-cluster/${K8S_ENVIRONMENT}-cluster/g" $n;
done
# Also change in user's kube config
sed -i "s/microk8s-cluster/${K8S_ENVIRONMENT}-cluster/g" ~/.kube/config

# Start MicroK8s
sudo "${indir}/../MicroK8S_Start.sh"

# Log inspection results
sudo microk8s inspect | sudo tee microk8s_inspect.log

# MicroK8s is installed and ready for use
echo "MicroK8s installation completed successfully."