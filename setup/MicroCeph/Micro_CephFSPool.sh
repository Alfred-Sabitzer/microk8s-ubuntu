#!/bin/bash
############################################################################################
#
# Create CephFS pools/filesystem and LXD storage entries for MicroCeph.
#
# Usage:
#   sudo ./Micro_CephFSPool.sh
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
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail
trap 'rc=$?; echo "Exiting with status $rc"; exit $rc' EXIT

# Allow overriding via environment / global variables; provide sane defaults
LXD_POOL_NAME="${LXD_POOL_NAME:-}"
LXD_POOL_PG_NUM="${LXD_POOL_PG_NUM:-}"
HOSTS=("${HOSTS[@]:-}")

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  -h, --help                 Show this help and exit
  -n, --lxd-pool-name NAME   Set LXD pool name (env: LXD_POOL_NAME). Default: ${LXD_POOL_NAME}
  -p, --lxd-pg-num NUM       Set placement group count (env: LXD_POOL_PG_NUM). Default: ${LXD_POOL_PG_NUM}
  -H, --hosts HOSTS          Comma- or space-separated list of Ceph hosts (env: HOSTS or top-level HOSTS array)
EOF
}

parse_args() {
  # Parse CLI args; allow short and long forms
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      -n|--lxd-pool-name)
        LXD_POOL_NAME="$2"; shift 2 ;;
      -p|--lxd-pg-num)
        LXD_POOL_PG_NUM="$2"; shift 2 ;;
      -H|--hosts)
        # accept comma or space separated list
        hosts_str="${2//,/ }"
        read -r -a HOSTS <<< "$hosts_str"
        shift 2 ;;
      --) shift; break ;;
      -*)
        echo "Unknown option: $1" >&2; usage; exit 2 ;;
      *)
        # positional args not used — stop parsing
        break ;;
    esac
  done

  # validate required parameters
  if [[ -z "${LXD_POOL_NAME}" ]]; then
    usage
    die "LXD_POOL_NAME must be set (use -n or set env var)"
  fi
  if [[ -z "${LXD_POOL_PG_NUM}" ]]; then
    LXD_POOL_PG_NUM=""
  else  
    if ! [[ "${LXD_POOL_PG_NUM}" =~ ^[0-9]+$ ]]; then
      usage
      die "LXD_POOL_PG_NUM must be an integer (got: ${LXD_POOL_PG_NUM})"
    fi 
  fi

  # Ensure HOSTS array exists (may be set earlier in the file or via --hosts)
  if [[ ${#HOSTS[@]} -eq 0 ]]; then
    # fallback default if the top of the script didn't set HOSTS
    HOSTS=(micro1.slainte.at micro2.slainte.at micro3.slainte.at micro4.slainte.at)
  fi
  CEPHFS_NAME=$LXD_POOL_NAME"_fs"
  CEPHFS_METADATA_POOL=$LXD_POOL_NAME"_metadata"
  CEPHFS_DATA_POOL=$LXD_POOL_NAME"_data"
}

# Helpers
die() { echo "Error: $*" >&2; exit 1; }

check_cmds() {
  # verify basics: snap-provided microceph wrapper and lxc
  if ! command -v microceph >/dev/null 2>&1 && ! command -v microceph.ceph >/dev/null 2>&1; then
    die "'microceph' snap not found. Many commands will fail without microceph." >&2
  fi
  if ! command -v lxc >/dev/null 2>&1; then
    die "'lxc' not found. LXD storage creation will be skipped." >&2
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

cephfs_exists() {
  sudo microceph.ceph fs ls 2>/dev/null | awk '{print $2}' | grep -wq -- "$CEPHFS_NAME" || return 1
}

create_cephfs() {
  if cephfs_exists; then
    die "CephFS '$CEPHFS_NAME' already exists. Skipping creation."
  fi
  echo "Creating CephFS '$CEPHFS_NAME' (metadata='$CEPHFS_METADATA_POOL', data='$CEPHFS_DATA_POOL')..."
  retry 5 5 sudo microceph.ceph fs new "$CEPHFS_NAME" "$CEPHFS_METADATA_POOL" "$CEPHFS_DATA_POOL" || die "Failed to create CephFS $CEPHFS_NAME"
}

create_pool() {
  local pool="$1"
  local pgnum="${2:-}"
  if pool_exists "$pool"; then
    die "Pool '$pool' already exists. Skipping."
  fi
  echo "Creating pool '$pool' '$pgnum'..."
  if [ -n "$pgnum" ]; then
    retry 5 5 sudo microceph.ceph osd pool create "$pool" "$pgnum" || die "Failed to create pool $pool"
  else
    retry 5 5 sudo microceph.ceph osd pool create "$pool" || die "Failed to create pool $pool"
  fi
  retry 5 5 sudo microceph.ceph osd pool set "$pool" pg_autoscale_mode on 
  retry 5 5 sudo microceph.ceph osd pool set "$pool" bulk true 
  retry 5 5 sudo microceph.ceph osd pool application enable "$pool" cephfs
}

main() {
    # Check required commands
    check_cmds
    # Run arg parsing for the script
    parse_args "$@"
    # List pools to verify creation
    echo "Existing Ceph pools:"
    sudo microceph.ceph osd pool ls || true

    echo "Creating CephFS pools..."
    create_pool "$CEPHFS_DATA_POOL" "$LXD_POOL_PG_NUM" || true
    create_pool "$CEPHFS_METADATA_POOL" "$LXD_POOL_PG_NUM" || true

    echo "Listing pools..."
    sudo microceph.ceph osd pool ls || true

    echo "Creating CephFS if not present..."
    create_cephfs || true

    # List filesystems to verify creation
    echo "Final Ceph state / filesystem listing..."
    sudo lxc storage list || true
    sudo microceph.ceph df || true
    sudo microceph.ceph fs ls || true
    echo "Checking MDS status..."
    sudo microceph.ceph mds stat || true

    echo "Ceph pools/filesystem and LXD storage setup completed successfully."
}

main "$@"
