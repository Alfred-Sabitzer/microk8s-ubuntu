#!/bin/bash
############################################################################################
#
# Stop microk8s
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail

echo "Stopping MicroK8s..."

if ! command -v microk8s &> /dev/null; then
  echo "Error: microk8s is not installed."
  exit 1
fi

max_retries=10
count=0

until sudo microk8s stop; do
  count=$((count+1))
  if [ $count -ge $max_retries ]; then
    echo "Failed to stop MicroK8s after $max_retries attempts."
    exit 1
  fi
  echo "Retrying microk8s stop in 30s... (Attempt $count/$max_retries)"
  sleep 30
done

echo "MicroK8s is stopped."
