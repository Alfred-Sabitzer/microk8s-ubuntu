#!/bin/bash
############################################################################################
#
# CDelete Ceph pools/filesystem and LXD storage entries for MicroCeph.
#
# Usage:
#   sudo ./Micro_delete_CephPool.sh
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

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  -h, --help                 Show this help and exit
  -n, --lxd-pool-name NAME   Set LXD pool name (env: LXD_POOL_NAME). Default: ${LXD_POOL_NAME}
EOF
}

parse_args() {
  # Parse CLI args; allow short and long forms
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      -n|--lxd-pool-name)
        LXD_POOL_NAME="$2"; shift 2 ;;
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

delete_pool() {
  local pool="$1"
  if ! pool_exists "$pool"; then
    die "Pool '$pool' does not exist. Skipping."
  fi
  echo "deleting pool '$pool' ..."

  retry 5 5 sudo microceph.ceph tell mon.* injectargs --mon_allow_pool_delete true
  retry 5 5 sudo microceph.ceph osd pool delete "$pool" "$pool" --yes-i-really-really-mean-it
  retry 5 5 sudo microceph.ceph tell mon.* injectargs --mon_allow_pool_delete false
}

main() {
    # Check required commands
    check_cmds
    # Run arg parsing for the script
    parse_args "$@"
    # List pools to verify creation
    echo "Existing Ceph pools:"
    sudo microceph.ceph osd pool ls || true

    echo "Deleting a block pool in LXD (name=${LXD_POOL_NAME}) ..."
    delete_pool "$LXD_POOL_NAME" 

    # List filesystems to verify creation
    echo "Final Ceph state / filesystem listing..."
    sudo microceph.ceph osd pool ls || true
    sudo microceph.ceph df || true
    sudo microceph.ceph fs ls || true
    echo "Checking MDS status..."
    sudo microceph.ceph mds stat || true

    echo "Ceph pools/filesystem and LXD storage setup completed successfully."
}

main "$@"
