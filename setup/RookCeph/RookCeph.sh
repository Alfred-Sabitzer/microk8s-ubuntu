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

main() {
  check_cmds

  echo "Checking sudo microk8s installation..."
  if ! command -v sudo microk8s >/dev/null 2>&1; then
    die "sudo microk8s not found. Install sudo microk8s and ensure it's in PATH."
  fi
  
  echo "Adding/updating rook helm repo (local helm wrapper) and updating..."
 # sudo microk8s helm repo add rook-release https://charts.rook.io/stable || true
  sudo microk8s helm repo update || true
  
  echo "Disabling rook-ceph (clean start)..."
  sudo microk8s disable rook-ceph --force || true  kubectl --namespace rook-ceph get pods -l "app=rook-ceph-operator"

  kubectl delete namespace ${NAMESPACE} --ignore-not-found=true || true
  kubectl delete namespace rook-ceph-external --ignore-not-found=true || true
  sleep 15

  echo "Enabling rook-ceph addon..."
  #sudo microk8s enable rook-ceph
  sudo microk8s enable rook-ceph --rook-version v1.18.7
  #sudo microk8s enable rook-ceph --rook-version  v1.16.2

  echo "Using sudo microk8s helm and kubectl for verification..."
  sudo microk8s helm ls --namespace ${NAMESPACE} || true
  sudo microk8s kubectl --namespace ${NAMESPACE} get pods -o wide || true
  kubectl --namespace rook-ceph get pods -l "app=rook-ceph-operator"
  echo "Waiting for rook-ceph-operator pod to be Ready..."
  sleep 10
  wait_for_pod_ready "${NAMESPACE}" "app=rook-ceph-operator" "300s"


  # Optional: connect to external Ceph cluster if files provided
  CEPh_CONF="/etc/ceph/ceph.conf"
  CEPh_KEYRING="/etc/ceph/ceph.keyring"
  RBD_POOL="${K8S_ENVIRONMENT}-rbd"

  if [ -f "${CEPh_CONF}" ] && [ -f "${CEPh_KEYRING}" ]; then
    sudo microk8s connect-external-ceph \
      --ceph-conf "${CEPh_CONF}" \
      --keyring "${CEPh_KEYRING}" \
      --rbd-pool "${RBD_POOL}" || echo "connect-external-ceph failed (ensure sudo microk8s supports this command)."
    sleep 5
    sudo microk8s kubectl --namespace rook-ceph-external get cephcluster || true
  else
    echo "No external Ceph conf/keyring found at ${CEPh_CONF} / ${CEPh_KEYRING}. Skipping external Ceph connection."
  fi

  echo "Waiting up to ${WAIT_SECONDS}s for rook-ceph pods to become Ready..."
  if ! sudo microk8s kubectl wait --for=condition=Ready pod -n "${NAMESPACE}" --timeout="${WAIT_SECONDS}s" 2>/dev/null; then
    echo "Warning: not all rook-ceph pods reported Ready within timeout. Check: sudo microk8s kubectl -n ${NAMESPACE} get pods -o wide"
  fi

  echo "Displaying rook-ceph cluster status..."
  sudo microk8s kubectl --namespace rook-ceph-external get cephcluster || true
  sudo microk8s kubectl --namespace rook-ceph get cephcluster || true

  echo "Listing storage classes..."
  sudo microk8s kubectl get storageclasses || true

  echo "Patching storageclasses defaults (if present)..."
  # attempt to make ceph-rbd default and unset hostpath default if present
  sudo microk8s kubectl patch storageclass microk8s-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}' || true
  sudo microk8s kubectl patch storageclass ceph-rbd -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' || true

  echo "Verifying storageclasses after patch..."
  sudo microk8s kubectl get storageclasses

  echo "Rook/Ceph setup complete."
  echo "Verify Rook and Ceph pods: sudo microk8s kubectl -n ${NAMESPACE} get pods"
}

main "$@"
exit