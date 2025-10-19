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
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
shopt -o -s nounset #-No Variables without definition
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
  ADMIN_PASS_FILE="./microceph_admin_pass_$$"
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

  echo "Setting Ceph configuration for dashboard and orchestrator..."
  sudo microceph.ceph mgr module enable microceph || die "Failed to enable microceph mgr module"
  sudo microceph.ceph orch set backend microceph || die "Failed to set orchestrator backend"
  sudo microceph.ceph orch status
  sudo microceph.ceph mgr module enable insights  || die "Failed to enable insights mgr module"
  sudo microceph.ceph mgr module enable alerts  || die "Failed to enable alerts mgr module"
  sudo microceph.ceph mgr module enable osd_perf_query || die "Failed to enable osd_perf_query mgr module"
  sudo microceph.ceph mgr module enable osd_support || die "Failed to enable osd_support mgr module"
  sudo microceph.ceph mgr module enable stats || die "Failed to enable stats mgr module"
  

  echo "Enabling RADOS Gateway (RGW) service..."
  # Check if RGW is already enabled
  if sudo microceph.ceph orch ls | grep -q rgw; then
    echo "RADOS Gateway (RGW) is already enabled."
  else
    echo "RADOS Gateway (RGW) is not enabled. Enabling now..."
    # use retry in case cluster not fully ready
    retry 5 10 sudo microceph enable rgw --target "$(hostname)" --port 8081 || die "Failed to enable RGW"
  fi
  
  echo "Creating RGW admin user (radosgw-admin)..."
  # create a user if not exist
  if ! sudo microceph.radosgw-admin user info --uid=admin >/dev/null 2>&1; then
    sudo microceph.radosgw-admin user create --uid=admin --display-name="Admin User" > /tmp/admin_user.json
    TMPFILES+=("/tmp/admin_user.json")
    echo "RGW admin user created and saved to /tmp/admin_user.json"
  else
    echo "RGW admin user 'admin' already exists."
  fi

  echo "Listing RADOS pools..."
  sudo microceph.rados lspools

  echo "Configuring Ceph dashboard..."
  # enable prometheus on microcloud
  sudo microceph.ceph mgr module enable prometheus || { echo "Failed to enable ceph prometheus module"; exit 3; }  
  sudo microceph.ceph config set mgr mgr/dashboard/server_port 8080 || die "Failed to set dashboard port"
  sudo microceph.ceph mgr module enable dashboard || die "Failed to enable dashboard"
  sudo microceph.ceph config set mgr mgr/dashboard/ssl false

  # create or update dashboard admin account securely
  prompt_admin_password
  echo "Creating dashboard admin user..."
  # ac-user-create requires file with password; use temp file created above
  sudo microceph.ceph dashboard ac-user-show admin >/dev/null 2>&1 && USER_EXISTS=true || USER_EXISTS=false 
  if [ "$USER_EXISTS" = false ]; then
    echo "Try to create Dashboard admin user"
    sudo microceph.ceph dashboard ac-user-create -i "$ADMIN_PASS_FILE" admin administrator || die "Failed to create admin user"
  else
    echo "Dashboard admin user already exists; updating password..."
    sudo microceph.ceph dashboard ac-user-set-password admin -i "$ADMIN_PASS_FILE" || die "Failed to set admin password"
  fi

  echo "Enabling telemetry and Prometheus metrics for RBD pools..."
  sudo microceph.ceph telemetry on --license sharing-1-0
  sudo microceph.ceph telemetry enable channel all || echo "Warning: telemetry enable failed"
  sudo microceph.ceph config set mgr mgr/prometheus/rbd_stats_pools "*" || true
  sudo microceph.ceph config set mgr mgr/prometheus/exclude_perf_counters false || true
  sudo microceph.ceph config set mon mon_allow_pool_delete true || die "Failed to set mon_allow_pool_delete"

  #echo "Listing Ceph authentication keys..."
  #sudo microceph.ceph auth ls

  sudo microceph.ceph mgr module ls

  echo "Verifying dashboard..."
  sudo microceph.ceph mgr services || die "Failed to get mgr services"
  echo "Access the Ceph dashboard at: http://$(hostname -I | awk '{print $1}'):8081 (user: admin)"


  echo "MicroCeph configuration completed successfully."
}

main "$@"
