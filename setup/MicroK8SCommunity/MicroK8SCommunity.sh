#!/bin/bash
############################################################################################
#
# Install Community and other sudo microk8s addons
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
set -euo pipefail

echo "Checking if sudo microk8s is installed..."
if ! command -v sudo microk8s &> /dev/null; then
  echo "Error: sudo microk8s is not installed. Please install sudo microk8s first."
  exit 1
fi

echo "Enabling required sudo microk8s addons..."

for addon in dns rbac hostpath-storage; do
  if sudo microk8s status | grep -q "$addon: enabled"; then
    echo "$addon is already enabled."
  else
    echo "Enabling $addon..."
    sudo microk8s enable "$addon"
  fi
done

echo "Waiting for sudo microk8s to be ready..."
sudo microk8s status --wait-ready

echo "Enabling community addons..."
if sudo microk8s status | grep -q "community: enabled"; then
  echo "community is already enabled."
else
  sudo microk8s enable community
fi

echo "Waiting for sudo microk8s to be ready..."
sudo microk8s status --wait-ready

echo "All required addons are enabled."