#!/bin/bash
############################################################################################
#
# Install and configure Rook/Ceph integration on MicroK8s.
# Purpose: enable rook-ceph addon, optionally connect to external Ceph,
#          verify storageclasses and set Ceph RBD as default storageclass.
#
# Usage: sudo ./RookCeph.sh
# Prerequisites: sudo microk8s installed, user in sudo microk8s group, optional external ceph conf/keyring
#
############################################################################################
set -euo pipefail
trap 'rc=$?; echo "Exiting with status $rc"; exit $rc' EXIT

indir=$(dirname "$0")

WAIT_SECONDS="${WAIT_SECONDS:-180}"
RETRY_ATTEMPTS=5
RETRY_DELAY=5
NAMESPACE="${NAMESPACE:-rook-ceph}"

KUBECTL="sudo microk8s.kubectl"
export external_namespace="rook-ceph-external"

die() {
  echo "Error: $*" >&2
  exit 1
}

check_cmds() {
  local req=(sudo microk8s kubectl helm)
  for c in "${req[@]}"; do
    if ! command -v "$c" >/dev/null 2>&1; then
      echo "Warning: $c not found in PATH. Will try sudo microk8s wrapper where appropriate."
    fi
  done
}

retry() {
  local attempts=$1; shift
  local delay=$1; shift
  local cmd=("$@")
  local i
  for i in $(seq 1 "$attempts"); do
    if "${cmd[@]}"; then
      return 0
    fi
    echo "Command failed (attempt $i/$attempts). Retrying in ${delay}s..."
    sleep "$delay"
  done
  return 1
}

wait_for_pod_ready() {
  local ns=$1; shift
  local selector=$1; shift
  local timeout=${1:-300s}
  echo "Waiting for pods (ns=${ns}, selector=${selector}) to be Ready (timeout=${timeout})..."
  sudo microk8s kubectl wait --for=condition=Ready pod -l "${selector}" -n "${ns}" --timeout="${timeout}"
}

# This is from /var/snap/microk8s/common/addons/core/addons/rook-ceph/plugin/rook-import-external-cluster.sh
CEPHFS_STORAGE_CLASS_NAME=cephfs
OPERATOR_NAMESPACE=rook-ceph # default set to rook-ceph
CSI_DRIVER_NAME_PREFIX=${CSI_DRIVER_NAME_PREFIX:-$OPERATOR_NAMESPACE}
CEPHFS_PROVISIONER=$CSI_DRIVER_NAME_PREFIX".cephfs.csi.ceph.com" # csi-provisioner-name
CLUSTER_ID_CEPHFS=$external_namespace

main() {
  check_cmds

  echo "Checking sudo microk8s installation..."
  if ! command -v sudo microk8s >/dev/null 2>&1; then
    die "sudo microk8s not found. Install sudo microk8s and ensure it's in PATH."
  fi

  # Optional: connect to external Ceph cluster if files provided
  CEPh_CONF="/etc/ceph/ceph.conf"
  CEPh_KEYRING="/etc/ceph/ceph.keyring"
  RBD_POOL="${K8S_ENVIRONMENT}-rbd"

  source /etc/ceph/vars_${K8S_ENVIRONMENT}.sh

  # # install rook toolbox for debugging
  # echo "Enabling rook-ceph toolbox..."
  # wget -qO- https://raw.githubusercontent.com/rook/rook/master/deploy/examples/toolbox.yaml > /tmp/toolbox.yaml
  # yq -i -y '.metadata.namespace = "rook-ceph-external"' /tmp/toolbox.yaml

  cephsecret=$(cat ${CEPh_KEYRING}  | grep -i 'key'  | awk '{print $3}')

  # Create the rook-ceph-admin secret in the rook-ceph-external namespace
  cat <<eof | $KUBECTL create -f -
apiVersion: v1
kind: Secret
type: kubernetes.io/rook
metadata:
  name: rook-ceph-admin
  namespace: rook-ceph-external
data:
  admin-secret: $(base64 -w0 <<< "admin-secret")
  ceph-secret: $(base64 -w0 <<< "${cephsecret}")
  ceph-username: $(base64 -w0 <<< "client.admin")
  cluster-name: $(base64 -w0 <<< "rook-ceph-external")
  fsid: $(base64 -w0 <<< "${ROOK_EXTERNAL_FSID}")
  mon-secret: $(base64 -w0 <<< "mon-secret")
eof

  # Create the rook-ceph-admin-endpoints configmap in the rook-ceph-external namespace
  cat <<eof | $KUBECTL create -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: rook-ceph-admin-endpoints
  namespace: rook-ceph-external
data:
  data: ${MONITORING_ENDPOINT}:${MONITORING_ENDPOINT_PORT}
eof


  echo ""
  echo "Finding YAML files in ${indir}..."
  mapfile -t yamls < <(find "${indir}" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort)

  if [ "${#yamls[@]}" -eq 0 ]; then
    echo "INFO: No YAML files found in ${indir}"
  else 
    echo "Found ${#yamls[@]} YAML file(s)."
    echo ""
    echo "========== Applying YAML Resources =========="
    for f in "${yamls[@]}"; do
      echo ""
      echo "Applying: $f"
      if ! retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" envsubst < "$f" | sudo microk8s kubectl apply -f - ; then
        die "Failed to apply $f after $RETRY_ATTEMPTS attempts"
      fi
    done
  fi

  echo ""
  echo "Check created resources in k8s cluster namespace '${NAMESPACE}'"
  echo ""

  wait_for_pod_ready "${external_namespace}" "app=rook-ceph-tools" "300s"

}

main "$@"
exit