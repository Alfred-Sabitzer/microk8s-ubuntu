#!/bin/bash
############################################################################################
#
# sudo microk8s Aufsetzen NFS-Service
# https://microk8s.io/docs/addon-nfs
#
# By default the volumes will be stored on a single node utilizing hostPath storage under /var/snap/microk8s/common/nfs-storage.
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail
#
# Erst disablen
sudo microk8s disable nfs
# Helm enablen
sudo microk8s status --wait-ready
sudo microk8s enable nfs
sudo microk8s status --wait-ready
#
