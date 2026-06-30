#!/bin/bash
############################################################################################
#
# Create Object storage pools for velero backup and restore using MicroCeph (RadosGW).
#
# Usage:
#   sudo ./Velero_create_buckets.sh
#
# Micro_Ceph_Objects.sh will be called to create the RadosGW object store, users and buckets.
# This script is from https://raw.githubusercontent.com/Alfred-Sabitzer/microk8s-ubuntu/refs/heads/main/setup/MicroCeph/Micro_Ceph_Objects.sh
# Download first and make it executable (chmod +x Micro_Ceph_Objects.sh) before running this script.
#
# Prerequisites:
#   - snap microceph installed and running (microceph.* commands available)
#   - RadosGW (ceph-rgw) service enabled
#   - Ceph CLI tools installed
#   - sudo privileges
#
# Notes:
#   - Adjust HOSTS, POOL names and PG count below if required.
#   - Script is idempotent where possible (checks for existing pools/filesystems/storage).
#   - RadosGW object store and users will be created if they don't exist.
#
############################################################################################
#shopt -o -s errexit #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail
trap 'rc=$?; echo "Exiting with status $rc"; exit $rc' EXIT

# ============================= CONFIG VARIABLES =============================
export BUCKET_NAME="k8s-velero"
export RADOSGW_USER="k8s-velero"
export USER_EMAIL="k8s-velero@slainte.at"
export RGW_REALM="default"
export RGW_ZONE_GROUP="default"
export RGW_ZONE="default"

# ============================= K8S =============================
./Micro_Ceph_Objects.sh --bucket-name "$BUCKET_NAME" \
    --radosgw-user "$RADOSGW_USER" \
    --user-email "$USER_EMAIL" \
    --rgw-realm "$RGW_REALM" \
    --rgw-zone-group "$RGW_ZONE_GROUP" \
    --rgw-zone "$RGW_ZONE"

# ============================= CONFIG VARIABLES =============================
export BUCKET_NAME="test-velero"
export RADOSGW_USER="test-velero"
export USER_EMAIL="test-velero@slainte.at"
export RGW_REALM="default"
export RGW_ZONE_GROUP="default"
export RGW_ZONE="default"

# ============================= test =============================
./Micro_Ceph_Objects.sh --bucket-name "$BUCKET_NAME" \
    --radosgw-user "$RADOSGW_USER" \
    --user-email "$USER_EMAIL" \
    --rgw-realm "$RGW_REALM" \
    --rgw-zone-group "$RGW_ZONE_GROUP" \
    --rgw-zone "$RGW_ZONE"

#