#!/bin/bash
############################################################################################
#
# Add support for Storagebuckets for Rook/Ceph external cluster
#
############################################################################################
set -euo pipefail
trap 'rc=$?; echo "Exiting with status $rc"; exit $rc' EXIT

sudo microk8s kubectl delete -f .
sudo microk8s kubectl apply -f .
