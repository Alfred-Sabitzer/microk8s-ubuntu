#!/bin/bash
############################################################################################
#
# Create Ceph pools/filesystem and LXD storage entries for MicroCeph.
#
# Usage:
#   sudo ./MicroCeph_Pool.sh
#
# Prerequisites:
#   - snap microceph installed and running (microceph.* commands available)
#   - LXD installed and configured (lxc available)
#   - sudo privileges
#
# Notes:
#   - Adjust HOSTS, POOL names and PG count below if required.
#   - Script is idempotent where possible (checks for existing pools/filesystems/storage).
#
############################################################################################
set -euo pipefail
trap 'rc=$?; echo "Exiting with status $rc"; exit $rc' EXIT

# Configurable variables
HOSTS=(micro1.slainte.at micro2.slainte.at micro3.slainte.at micro4.slainte.at)
CEPHFS_METADATA_POOL="cephfs_metadata"
CEPHFS_DATA_POOL="cephfs_data"
CEPHFS_NAME="cephfs"
LXD_POOL_NAME="lxdpool"
LXD_POOL_PG_NUM=32

# Helpers
die() { echo "Error: $*" >&2; exit 1; }

check_cmds() {
  # verify basics: snap-provided microceph wrapper and lxc
  if ! command -v microceph >/dev/null 2>&1 && ! command -v microceph.ceph >/dev/null 2>&1; then
    echo "Warning: 'microceph' snap not found. Many commands will fail without microceph." >&2
  fi
  if ! command -v lxc >/dev/null 2>&1; then
    echo "Warning: 'lxc' not found. LXD storage creation will be skipped." >&2
  fi
}

retry() {
  # retry <attempts> <delay> -- cmd...
  local attempts=$1; shift
  local delay=$1; shift
  local i
  for ((i=1;i<=attempts;i++)); do
    if "$@"; then
      return 0
    fi
    echo "Command failed (attempt ${i}/${attempts}). Retrying in ${delay}s..."
    sleep "${delay}"
  done
  return 1
}

pool_exists() {
  local pool="$1"
  # returns 0 if pool exists
  if sudo microceph.ceph osd pool ls 2>/dev/null | grep -wq -- "$pool"; then
    return 0
  fi
  return 1
}

create_pool() {
  local pool="$1"
  local pgnum="${2:-}"
  if pool_exists "$pool"; then
    echo "Pool '$pool' already exists. Skipping."
    return 0
  fi
  echo "Creating pool '$pool'..."
  if [ -n "$pgnum" ]; then
    retry 5 5 sudo microceph.ceph osd pool create "$pool" "$pgnum" || die "Failed to create pool $pool"
  else
    retry 5 5 sudo microceph.ceph osd pool create "$pool" || die "Failed to create pool $pool"
  fi
}

cephfs_exists() {
  sudo microceph.ceph fs ls 2>/dev/null | awk '{print $2}' | grep -wq -- "$CEPHFS_NAME" || return 1
}

create_cephfs() {
  if cephfs_exists; then
    echo "CephFS '$CEPHFS_NAME' already exists. Skipping creation."
    return 0
  fi
  echo "Creating CephFS '$CEPHFS_NAME' (metadata='$CEPHFS_METADATA_POOL', data='$CEPHFS_DATA_POOL')..."
  retry 5 5 sudo microceph.ceph fs new "$CEPHFS_NAME" "$CEPHFS_METADATA_POOL" "$CEPHFS_DATA_POOL" || die "Failed to create CephFS $CEPHFS_NAME"
}

create_lxd_storage_for_host() {
  local storage_name="$1"
  local driver_name="${2:-ceph}"
  local source_pool="$3"
  local target="${4:-}"

  if ! command -v lxc >/dev/null 2>&1; then
    echo "Skipping LXD storage creation; lxc not available."
    return 0
  fi

  if sudo lxc storage show "$storage_name" >/dev/null 2>&1; then
    echo "LXD storage '$storage_name' already exists. Skipping for target ${target:-local}."
    return 0
  fi

  if [ -n "$target" ]; then
    echo "Creating LXD storage '$storage_name' on target '${target}' using source='${source_pool}'..."
    if ! sudo lxc storage create "$storage_name" "$driver_name" --target "$target" source="$source_pool"; then
      echo "Warning: failed to create storage '$storage_name' on target '$target'." >&2
    fi
  else
    echo "Creating LXD storage '$storage_name' on local host using source='${source_pool}'..."
    if ! sudo lxc storage create "$storage_name" "$driver_name" source="$source_pool"; then
      echo "Warning: failed to create local storage '$storage_name'." >&2
    fi
  fi
}

main() {
    check_cmds

    # List pools to verify creation
    echo "Existing Ceph pools:"
    sudo microceph.ceph osd pool ls || true

    echo "Creating CephFS pools..."
    create_pool "$CEPHFS_DATA_POOL" || true
    # set pool options (best-effort)
    sudo microceph.ceph osd pool set "$CEPHFS_DATA_POOL" bulk true >/dev/null 2>&1 || true
    sudo microceph.ceph osd pool application enable "$CEPHFS_DATA_POOL" cephfs

    create_pool "$CEPHFS_METADATA_POOL" || true
    sudo microceph.ceph osd pool set "$CEPHFS_METADATA_POOL" bulk true >/dev/null 2>&1 || true
    sudo microceph.ceph osd pool application enable "$CEPHFS_METADATA_POOL" cephfs

    echo "Listing pools..."
    sudo microceph.ceph osd pool ls || true

    echo "Creating CephFS if not present..."
    create_cephfs || true

    # List filesystems to verify creation
    echo "Final Ceph state / filesystem listing..."
    sudo microceph.ceph df || true
    sudo microceph.ceph fs ls || true
    echo "Checking MDS status..."
    sudo microceph.ceph mds stat || true


    # Create a CephFS pool in LXD
    sudo lxc storage create cephfs cephfs --target micro1.slainte.at source=cephfs 
    sudo lxc storage create cephfs cephfs --target micro2.slainte.at source=cephfs 
    sudo lxc storage create cephfs cephfs --target micro3.slainte.at source=cephfs 
    sudo lxc storage create cephfs cephfs --target micro4.slainte.at source=cephfs 
    sudo lxc storage create cephfs cephfs

    echo "Creating a block pool for LXD (name=${LXD_POOL_NAME})..."
    create_pool "$LXD_POOL_NAME" "$LXD_POOL_PG_NUM" || true
    sudo microceph.ceph osd pool set "$LXD_POOL_NAME" bulk true >/dev/null 2>&1 || true
    sudo microceph.ceph osd pool application enable "$LXD_POOL_NAME" rbd

    # Create a Ceph pool in LXD
    sudo lxc storage create default ceph --target micro1.slainte.at source=${LXD_POOL_NAME}
    sudo lxc storage create default ceph --target micro2.slainte.at source=${LXD_POOL_NAME}
    sudo lxc storage create default ceph --target micro3.slainte.at source=${LXD_POOL_NAME}
    sudo lxc storage create default ceph --target micro4.slainte.at source=${LXD_POOL_NAME}
    sudo lxc storage create default ceph 


    echo "Verifying LXD storage list..."
    if command -v lxc >/dev/null 2>&1; then
        sudo lxc storage list || true
    fi

    echo "Ceph pools/filesystem and LXD storage setup completed successfully."
}

main "$@"
