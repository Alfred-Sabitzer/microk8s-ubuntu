#!/bin/bash
############################################################################################
#
# configure MicroCeph.
# Installation has been done with MicroCloud installer
#
# Usage: sudo ./MicroCeph.sh
# Prerequisites: snap microceph installed, sudo privileges
#
############################################################################################
set -euo pipefail
trap 'rc=$?; cleanup; exit $rc' EXIT

indir=$(dirname "$0")
ADMIN_PASS_FILE=""
TMPFILES=()

die() {
  echo "Error: $*" >&2
  exit 1
}

cleanup() {
  # remove any temporary files created
  for f in "${TMPFILES[@]:-}"; do
    [ -f "$f" ] && sudo rm -f "$f"
  done
}

check_cmds() {
  local cmds=(microceph radosgw-admin ceph netstat curl)
  for c in "${cmds[@]}"; do
    if ! command -v "$c" >/dev/null 2>&1; then
      die "Required command not found: $c"
    fi
  done
}

retry() {
  # retry <retries> <delay> -- command...
  local retries=$1; shift
  local delay=$1; shift
  local i
  for i in $(seq 1 "$retries"); do
    if "$@"; then
      return 0
    fi
    echo "Command failed: attempt $i/$retries. Retrying in ${delay}s..."
    sleep "$delay"
  done
  return 1
}

prompt_admin_password() {
  if [ -n "${ADMIN_PASS:-}" ]; then
    echo "Using ADMIN_PASS from environment."
    ADMIN_PASS="$ADMIN_PASS"
  else
    echo -n "Enter password for Ceph dashboard admin user (will not echo): "
    read -rs ADMIN_PASS || die "Failed to read password"
    echo
  fi
  ADMIN_PASS_FILE="/tmp/microceph_admin_pass_$$"
  TMPFILES+=("$ADMIN_PASS_FILE")
  echo -n "$ADMIN_PASS" | sudo tee "$ADMIN_PASS_FILE" >/dev/null
  sudo chmod 600 "$ADMIN_PASS_FILE"
}

ensure_microceph_running() {
  if ! sudo microceph.ceph status >/dev/null 2>&1; then
    die "microceph is not running. Please check the installation and start microceph first."
  fi
}

main() {
  check_cmds
  ensure_microceph_running

  echo "Checking network services (netstat) ..."
  if ! sudo netstat -tulpen >/dev/null 2>&1; then
    echo "Warning: netstat unavailable or failed. Install net-tools if needed."
  fi

  echo "Enabling RADOS Gateway (RGW) service..."
  # use retry in case cluster not fully ready
  retry 5 10 sudo microceph enable rgw --target "$(hostname)" --port 8081 || die "Failed to enable RGW"

  echo "Creating RGW admin user (radosgw-admin)..."
  # create a user if not exist
  if ! sudo radosgw-admin user info --uid=admin >/dev/null 2>&1; then
    sudo radosgw-admin user create --uid=admin --display-name="Admin User" > /tmp/admin_user.json
    TMPFILES+=("/tmp/admin_user.json")
    echo "RGW admin user created and saved to /tmp/admin_user.json"
  else
    echo "RGW admin user 'admin' already exists."
  fi

  echo "Setting Ceph configuration for dashboard and orchestrator..."
  sudo ceph config set mon mon_allow_pool_delete true || die "Failed to set mon_allow_pool_delete"
  sudo ceph orch set backend microceph || die "Failed to set orchestrator backend"
  sudo microceph.ceph orch status

  echo "Listing RADOS pools..."
  sudo microceph.rados lspools

  echo "Configuring Ceph dashboard..."
  sudo microceph.ceph mgr module ls
  sudo microceph.ceph config set mgr mgr/dashboard/server_port 8081
  sudo microceph.ceph mgr module enable dashboard || die "Failed to enable dashboard"
  sudo microceph.ceph config set mgr mgr/dashboard/ssl false

  # create or update dashboard admin account securely
  prompt_admin_password
  echo "Creating dashboard admin user..."
  # ac-user-create requires file with password; use temp file created above
  if ! sudo microceph.ceph dashboard ac-user-create -i "$ADMIN_PASS_FILE" admin administrator >/dev/null 2>&1; then
    echo "Dashboard user creation failed or user may already exist; attempting to update password..."
    sudo microceph.ceph dashboard ac-user-set-password admin "$ADMIN_PASS" || die "Failed to set admin password"
  fi

  echo "Verifying dashboard..."
  sudo microceph.ceph mgr services || die "Failed to get mgr services"
  echo "Access the Ceph dashboard at: http://$(hostname -I | awk '{print $1}'):8081 (user: admin)"

  echo "Enabling telemetry and Prometheus metrics for RBD pools..."
  sudo ceph telemetry enable channel all || echo "Warning: telemetry enable failed"
  sudo ceph config set mgr mgr/prometheus/rbd_stats_pools "*" || true
  sudo ceph config set mgr mgr/prometheus/exclude_perf_counters false || true

  echo "MicroCeph configuration completed successfully."
}

main "$@"
