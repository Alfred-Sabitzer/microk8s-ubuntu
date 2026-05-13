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

create_bucket() {
  local bucket_name="$1"
  local user_name="$2"
  
  log_info "Creating bucket: $bucket_name"
  
  # Check if bucket already exists
  if sudo radosgw-admin bucket list 2>/dev/null | grep -q "\"$bucket_name\""; then
    log_warning "Bucket '$bucket_name' already exists. Skipping creation."
    return 0
  fi
  
cat << EOF > /home/ansible/.s3cfg
[default]
access_key = $(sudo radosgw-admin user info --uid="$user_name" | grep '"access_key"' | awk -F'"' '{print $4}')
secret_key = $(sudo radosgw-admin user info --uid="$user_name" | grep '"secret_key"' | awk -F'"' '{print $4}')

# RGW endpoint
host_base = 192.168.0.194:8081
host_bucket = 192.168.0.194:8081/%(bucket)

# Ceph RGW specifics
use_https = False
signature_v2 = False
signature_v4 = True

# Required for RGW
bucket_location = us-east-1

# Disable AWS-specific behavior
guess_mime_type = True
use_mime_magic = True
enable_multipart = True

# Encryption (optional, client-side)
encrypt = False
# If you want client-side encryption, set encrypt=True and uncomment:
# encryption_password =  $(sudo radosgw-admin user info --uid="$user_name" | grep '"secret_key"' | awk -F'"' '{print $4}')

# Performance & compatibility
socket_timeout = 300
check_ssl_certificate = False
check_ssl_hostname = False

# Logging
verbosity = WARNING
EOF

  #
  # Note: Actual bucket creation requires S3-compatible tool (e.g., s3cmd, AWS CLI).
  #
  s3cmd mb s3://$bucket_name --config=/home/ansible/.s3cfg
  log_success "Bucket '$bucket_name' created successfully."
  sudo radosgw-admin bucket list  
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

display_object_store_details() {
  local realm="$1"
  
  log_info "Object Store Details:"
  echo "=================================================="
  echo "Realm: $realm"
  
  if command_exists radosgw-admin; then
    radosgw-admin realm get --realm="$realm" 2>/dev/null | grep -E "name|id" || true
    echo ""
    
    echo "Zone Groups:"
    radosgw-admin zonegroup list --realm="$realm" 2>/dev/null || true
    echo ""
    
    echo "Zones:"
    radosgw-admin zone list --realm="$realm" 2>/dev/null || true
  fi
  echo "=================================================="
}

display_bucket_details() {
  local bucket_name="$1"
  
  log_info "Bucket Details:"
  echo "=================================================="
  echo "Bucket Name: $bucket_name"
  
  if command_exists radosgw-admin; then
    radosgw-admin bucket stats --bucket="$bucket_name" 2>/dev/null | head -20 || echo "Bucket stats not yet available"
    echo ""
    
    echo "Bucket Info:"
    radosgw-admin bucket info --bucket="$bucket_name" 2>/dev/null || echo "Bucket info not yet available"
  fi
  echo "=================================================="
}

display_demo_commands() {
  local bucket_name="$1"
  local user_name="$2"
  
  log_info "Demo Commands - Using RadosGW S3 Interface:"
  echo "=================================================="
  echo ""
  echo "# Prerequisites:"
  echo "#  - Install s3cmd: apt-get install s3cmd"
  echo ""
  echo "# 1. Recommended: use s3cmd to access RadosGW (examples below)."
  echo ""
  echo ""
  echo "  # Set these variables (example endpoint and credentials):"
  echo "  sudo cat /var/snap/microceph/current/conf/radosgw.conf | grep 'rgw frontends'"
  echo "  RGW_ENDPOINT=http://192.168.0.194:8081"
  echo ""
  echo "  #check ports and IPs accordingly"
  echo "  curl -k -v \$RGW_ENDPOINT"
  echo ""
  echo "  export S3CMD_HOST=\$RGW_ENDPOINT" 
  echo "  export user_name=\"$user_name\"" 
  echo "  export bucket_name=\"$bucket_name\"" 
  echo ""
  echo "# 2. Create bucket (s3cmd):"
  echo "   s3cmd mb s3://\$bucket_name"
  echo ""
  echo "# 3. List all buckets (s3cmd):"
  echo "   s3cmd ls"
  echo ""
  echo "# 4. Upload a file to bucket (s3cmd):"
  echo "   s3cmd put ./.s3cfg s3://\$bucket_name/"
  echo ""
  echo "# 5. List bucket contents (s3cmd):"
  echo "   s3cmd ls s3://\$bucket_name/"
  echo ""
  echo "# 6. Download a file from bucket (s3cmd):"
  echo "   s3cmd get s3://\$bucket_name/.s3cfg /tmp/.s3cfg.downloaded"
  echo ""
  echo "# 7. Delete a file from bucket (s3cmd):"
  echo "   s3cmd del s3://\$bucket_name/.s3cfg"
  echo ""
  echo "# 8. List bucket contents (s3cmd): should be empty now"
  echo "   s3cmd ls s3://\$bucket_name/"
  echo ""
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
create_bucket "$BUCKET_NAME" "$RADOSGW_USER"
display_user_credentials "$RADOSGW_USER"
display_object_store_details "$RGW_REALM"
display_bucket_details "$BUCKET_NAME"
display_demo_commands "$BUCKET_NAME" "$RADOSGW_USER"

log_success "=========================================="
log_success "Object store and user setup completed!"
log_success "=========================================="
