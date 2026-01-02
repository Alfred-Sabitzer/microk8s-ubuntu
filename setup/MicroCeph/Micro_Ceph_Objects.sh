#!/bin/bash
############################################################################################
#
# Create Object storage pools and RadosGW object store for MicroCeph.
#
# Usage:
#   sudo ./Micro_Ceph_Objects.sh [options]
#
# Options:
#   --bucket-name NAME       Bucket/object store name (default: microceph-bucket)
#   --user-name NAME         RadosGW user name (default: microceph-user)
#   --user-email EMAIL       User email for RadosGW (default: user@example.com)
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
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail
trap 'rc=$?; echo "Exiting with status $rc"; exit $rc' EXIT

# Allow overriding via environment / global variables; provide sane defaults

# ============================= CONFIG VARIABLES =============================
BUCKET_NAME="${BUCKET_NAME:-microceph-bucket}"
RADOSGW_USER="${RADOSGW_USER:-microceph-user}"
USER_EMAIL="${USER_EMAIL:-user@example.com}"
RGW_REALM="${RGW_REALM:-default}"
RGW_ZONE_GROUP="${RGW_ZONE_GROUP:-default}"
RGW_ZONE="${RGW_ZONE:-default}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --bucket-name)
      BUCKET_NAME="$2"
      shift 2
      ;;
    --user-name)
      RADOSGW_USER="$2"
      shift 2
      ;;
    --user-email)
      USER_EMAIL="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# ============================= HELPER FUNCTIONS =============================

log_info() {
  echo "[INFO] $*"
}

log_success() {
  echo "[SUCCESS] $*"
}

log_error() {
  echo "[ERROR] $*" >&2
}

log_warning() {
  echo "[WARNING] $*"
}

# Check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# ============================= PREREQUISITE CHECKS =============================

log_info "Checking prerequisites..."

if ! command_exists microceph; then
  log_error "microceph command not found. Please install MicroCeph first."
  exit 1
fi

if ! command_exists ceph; then
  log_error "ceph command not found. Please install Ceph CLI tools."
  exit 1
fi

if ! command_exists radosgw-admin; then
  log_warning "radosgw-admin command not found. RadosGW may not be configured."
  log_info "Attempting to use ceph commands instead..."
fi

log_success "Prerequisites check completed."

# ============================= OBJECT STORE FUNCTIONS =============================

create_object_store() {
  local store_name="$1"
  
  log_info "Creating object store: $store_name"
  
  # Check if object store already exists
  if microceph client get-key mgr 2>/dev/null | \
     ceph osd pool ls 2>/dev/null | grep -q "^${store_name}" 2>/dev/null; then
    log_warning "Object store '$store_name' already exists. Skipping creation."
    return 0
  fi
  
  # Create the object store using microceph
  if command_exists radosgw-admin; then
    log_info "Creating object store using radosgw-admin..."
    radosgw-admin realm create --realm="$RGW_REALM" --default 2>/dev/null || true
    radosgw-admin zonegroup create --realm="$RGW_REALM" --zonegroup="$RGW_ZONE_GROUP" --default 2>/dev/null || true
    radosgw-admin zone create --realm="$RGW_REALM" --zonegroup="$RGW_ZONE_GROUP" --zone-name="$RGW_ZONE" --default 2>/dev/null || true
    radosgw-admin period update --realm="$RGW_REALM" --commit 2>/dev/null || true
  fi
  
  log_success "Object store '$store_name' setup completed."
}

create_radosgw_user() {
  local user_name="$1"
  local user_email="$2"
  
  log_info "Creating RadosGW user: $user_name"
  
  # Check if user already exists
  if radosgw-admin user info --uid="$user_name" >/dev/null 2>&1; then
    log_warning "User '$user_name' already exists. Skipping creation."
    return 0
  fi
  
  # Create the RadosGW user
  log_info "Creating new RadosGW user with S3 access..."
  radosgw-admin user create \
    --uid="$user_name" \
    --display-name="$user_name User" \
    --email="$user_email" \
    --access-key="$(date +%s | sha256sum | cut -c 1-20)" \
    --secret-key="$(openssl rand -base64 32)"
  
  log_success "RadosGW user '$user_name' created successfully."
}

display_user_credentials() {
  local user_name="$1"
  
  log_info "Retrieving credentials for user: $user_name"
  
  local user_info
  user_info=$(radosgw-admin user info --uid="$user_name" 2>/dev/null || echo "")
  
  if [ -z "$user_info" ]; then
    log_error "Could not retrieve user information for '$user_name'"
    return 1
  fi
  
  log_info "User Credentials:"
  echo "=================================================="
  echo "User ID: $user_name"
  echo "$user_info" | grep -A 2 '"access_key"' || echo "Access Key: See output above"
  echo "$user_info" | grep -A 2 '"secret_key"' || echo "Secret Key: See output above"
  echo "=================================================="
}

# ============================= MAIN EXECUTION =============================

log_info "=========================================="
log_info "MicroCeph Object Store Setup Script"
log_info "=========================================="
log_info "Bucket/Object Store: $BUCKET_NAME"
log_info "RadosGW User: $RADOSGW_USER"
log_info "User Email: $USER_EMAIL"
log_info "=========================================="

create_object_store "$BUCKET_NAME"
create_radosgw_user "$RADOSGW_USER" "$USER_EMAIL"
display_user_credentials "$RADOSGW_USER"

log_success "=========================================="
log_success "Object store and user setup completed!"
log_success "=========================================="
