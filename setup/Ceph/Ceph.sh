#!/bin/bash
############################################################################################
#
# htps://docs.ceph.com/en/reef/
# https://docs.ceph.com/en/reef/cephadm/install/#cephadm-deploying-new-cluster
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it’s executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail
indir=$(dirname "$0")

# # We need docker first
# sudo apt update
# sudo apt install apt-transport-https curl ca-certificates gnupg lsb-release -y
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
# echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
# sudo apt update
# #
# sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
# #

# We do it with podman now
# Ubuntu 20.10 and newer
sudo apt-get update
sudo apt-get -y install podman

# Install cephadm
if [ -f /etc/ceph/ceph.conf ]; then
    echo "Ceph is already installed. Exiting."
    exit 0
fi

CEPH_RELEASE=19.2.2 # replace this with the active release
curl --silent --remote-name --location https://download.ceph.com/rpm-${CEPH_RELEASE}/el9/noarch/cephadm
sudo chmod +x cephadm

sudo ./cephadm add-repo --version ${CEPH_RELEASE} # this will bring an error (Ubuntu 24.04 is not supported by cephadm yet)
if [ $? -ne 0 ]; then
    echo "Warning: cephadm add-repo failed, but we will continue anyway."
fi
sudo ./cephadm install ceph-common

# Bootstrap the cluster
if [ -f /etc/ceph/ceph.conf ]; then
    echo "Ceph is already installed. Exiting."
    exit 0
fi
sudo ./cephadm bootstrap --mon-ip  $(hostname -I | awk '{print $1}') --allow-fqdn-hostname # --no-cleanup-on-failure --allow-overwrite 

ceph orch apply osd --all-available-devices
ceph orch apply mds
ceph orch apply rgw
ceph orch apply mgr
ceph orch apply nfs
ceph orch apply dashboard
ceph orch apply mgr dashboard
ceph orch apply host $(hostname -I | awk '{print $1}') --label cephadm
ceph orch apply host $(hostname -I | awk '{print $1}') --label cephadm --all-available-devices  


