#!/bin/bash
############################################################################################
#
# sudo microk8s Konfiguration Helm
#
# Infer repository core for addon helm3
# Helm comes pre-installed with MicroK8s
#
############################################################################################
set -euo pipefail

echo "Checking if sudo microk8s is installed..."
if ! command -v sudo microk8s &> /dev/null; then
  echo "Error: sudo microk8s is not installed. Please install sudo microk8s first."
  exit 1
fi

echo "Disabling helm3 if enabled..."
sudo microk8s disable helm3 || true

sudo microk8s status --wait-ready

echo "Enabling helm3 addon..."
sudo microk8s enable helm3

echo "Setting up helm alias (requires sudo)..."
if sudo -n true 2>/dev/null; then
  sudo snap unalias helm || true
  sudo snap alias microk8s.helm3 helm
else
  echo "Warning: Could not set helm alias. Please run:"
  echo "  sudo snap unalias helm || true"
  echo "  sudo snap alias microk8s.helm3 helm"
fi

echo "Helm is now ready to use via 'helm' command."

