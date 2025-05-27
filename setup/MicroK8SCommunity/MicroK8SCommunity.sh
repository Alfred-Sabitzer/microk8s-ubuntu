#!/bin/bash
############################################################################################
#
# Install Community and other MicroK8S addons
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it’
set -euo pipefail

echo "Checking if microk8s is installed..."
if ! command -v microk8s &> /dev/null; then
  echo "Error: microk8s is not installed. Please install microk8s first."
  exit 1
fi

echo "Enabling required MicroK8S addons..."

for addon in dns rbac hostpath-storage; do
  if microk8s status | grep -q "$addon: enabled"; then
    echo "$addon is already enabled."
  else
    echo "Enabling $addon..."
    microk8s enable "$addon"
  fi
done

echo "Waiting for MicroK8S to be ready..."
microk8s status --wait-ready

echo "Enabling community addons..."
if microk8s status | grep -q "community: enabled"; then
  echo "community is already enabled."
else
  microk8s enable community
fi

echo "Waiting for MicroK8S to be ready..."
microk8s status --wait-ready

echo "All required addons are enabled."