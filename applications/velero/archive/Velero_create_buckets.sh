#!/bin/bash
############################################################################################
#
# Create Object storage pools for velero backup and restore using MicroCeph (RadosGW).
#
# Usage:
#   sudo ./Velero_create_buckets.sh
#
# The helper script from setup/MicroCeph/Micro_Ceph_Objects.sh is invoked to create
# the RadosGW object store, user and bucket.
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
    --user-name "$RADOSGW_USER" \
    --user-email "$USER_EMAIL"

# ============================= CONFIG VARIABLES =============================
export BUCKET_NAME="test-velero"
export RADOSGW_USER="test-velero"
export USER_EMAIL="test-velero@slainte.at"
export RGW_REALM="default"
export RGW_ZONE_GROUP="default"
export RGW_ZONE="default"

# ============================= test =============================
./Micro_Ceph_Objects.sh --bucket-name "$BUCKET_NAME" \
    --user-name "$RADOSGW_USER" \
    --user-email "$USER_EMAIL"

#