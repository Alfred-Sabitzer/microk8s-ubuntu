#!/bin/bash
############################################################################################
#
# MicroK8S Konfiguration Helm
#
# Infer repository core for addon helm3
# Helm comes pre-installed with MicroK8s
#
############################################################################################
set -euo pipefail

echo "Checking if microk8s is installed..."
if ! command -v microk8s &> /dev/null; then
  echo "Error: microk8s is not installed. Please install microk8s first."
  exit 1
fi

echo "Disabling helm3 if enabled..."
microk8s disable helm3 || true

microk8s status --wait-ready

echo "Enabling helm3 addon..."
microk8s enable helm3

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

