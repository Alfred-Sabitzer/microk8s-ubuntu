#!/bin/bash
############################################################################################
#
# Install and configure Rook/Ceph integration on MicroK8s.
# Purpose: enable rook-ceph addon, optionally connect to external Ceph,
#          verify storageclasses and set Ceph RBD as default storageclass.
#
# Usage: sudo ./RookCeph.sh
# Prerequisites: microk8s installed, user in microk8s group, optional external ceph conf/keyring
#
############################################################################################
set -euo pipefail
trap 'rc=$?; echo "Exiting with status $rc"; exit $rc' EXIT

indir=$(dirname "$0")

die() {
  echo "Error: $*" >&2
  exit 1
}

check_cmds() {
  local req=(microk8s kubectl helm)
  for c in "${req[@]}"; do
    if ! command -v "$c" >/dev/null 2>&1; then
      echo "Warning: $c not found in PATH. Will try microk8s wrapper where appropriate."
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
  microk8s kubectl wait --for=condition=Ready pod -l "${selector}" -n "${ns}" --timeout="${timeout}"
}

main() {
  check_cmds

  echo "Checking MicroK8s installation..."
  if ! command -v microk8s >/dev/null 2>&1; then
    die "microk8s not found. Install MicroK8s and ensure it's in PATH."
  fi

  echo "Disabling rook-ceph (clean start)..."
  microk8s disable rook-ceph --force || true

  echo "Enabling rook-ceph addon..."
  microk8s enable rook-ceph

  echo "Using microk8s helm and kubectl for verification..."
  microk8s helm ls --namespace rook-ceph || true
  microk8s kubectl --namespace rook-ceph get pods -l "app=rook-ceph-operator" -o wide || true

  wait_for_pod_ready "rook-ceph" "app=rook-ceph-operator" "300s"

  echo "Adding/updating rook helm repo (local helm wrapper) and updating..."
  microk8s helm repo add rook-release https://charts.rook.io/release || true
  microk8s helm repo update || true

  # Optional: connect to external Ceph cluster if files provided
  CEPh_CONF="/home/ansible/ceph/ceph.conf"
  CEPh_KEYRING="/home/ansible/ceph/ceph.keyring"
  RBD_POOL="microk8s-rbd"

  if [ -f "${CEPh_CONF}" ] && [ -f "${CEPh_KEYRING}" ]; then
    echo "Connecting Rook operator to external Ceph cluster using provided ceph.conf/keyring..."
    microk8s connect-external-ceph \
      --ceph-conf "${CEPh_CONF}" \
      --keyring "${CEPh_KEYRING}" \
      --rbd-pool "${RBD_POOL}" || echo "connect-external-ceph failed (ensure microk8s supports this command)."
    sleep 5
    microk8s kubectl --namespace rook-ceph-external get cephcluster || true
  else
    echo "No external Ceph conf/keyring found at ${CEPh_CONF} / ${CEPh_KEYRING}. Skipping external Ceph connection."
  fi

  echo "Listing storage classes..."
  microk8s kubectl get storageclasses || true

  echo "Patching storageclasses defaults (if present)..."
  # attempt to make ceph-rbd default and unset hostpath default if present
  microk8s kubectl patch storageclass microk8s-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}' || true
  microk8s kubectl patch storageclass ceph-rbd -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' || true

  echo "Verifying storageclasses after patch..."
  microk8s kubectl get storageclasses

  echo "Rook/Ceph setup complete."
  echo "Verify Rook and Ceph pods: microk8s kubectl -n rook-ceph get pods"
}

main "$@"

