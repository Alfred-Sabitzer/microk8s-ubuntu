#!/bin/bash
############################################################################################
#
# Install and configure Ceph on MicroK8s
# Aim is to have encrypted disks, based on secrets in openbao
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail
indir=$(dirname "$0")

echo "Checking if sudo microk8s is installed..."
if ! command -v sudo microk8s &> /dev/null; then
  echo "Error: sudo microk8s is not installed."
  exit 1
fi

# https://docs.ceph.com/en/mimic/start/quick-start-preflight/#debian-ubuntu
# Prerequisites for Ubuntu 24.04 LTS

wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -
echo deb https://download.ceph.com/debian-squid/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list

sudo apt update
sudo apt install ceph-deploy ceph ceph-common
sudo apt install ntp
