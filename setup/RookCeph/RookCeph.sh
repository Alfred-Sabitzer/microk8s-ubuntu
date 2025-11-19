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

WAIT_SECONDS="${WAIT_SECONDS:-180}"
RETRY_ATTEMPTS=5
RETRY_DELAY=5
NAMESPACE="${NAMESPACE:-rook-ceph}"

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
  return 1
}

wait_for_pod_ready() {
  local ns=$1; shift
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
  if ! command -v microk8s >/dev/nu
echo "Running write (syncing after write) ..."
{ time_out=$($TIME_CMD "${WRITE_CMD[@]}" 2>&1) ; } || true
# make sure data is flushed
sync || true
echo "Write finished."
echo "${time_out}"#!/bin/bash
############################################################################################
# Connect to a shell inside a Kubernetes pod/container.
# Usage: ./kexec.shll 2>&1; then
    die "microk8s not found. Install MicroK8s and ensure it's in PATH."
  fi
  
  echo "Adding/updating rook helm repo (local helm wrapper) and updating..."
 # microk8s helm repo add rook-release https://charts.rook.io/stable || true
  microk8s helm repo update || true
  
  echo "Disabling rook-ceph (clean start)..."
  microk8s disable rook-ceph --force || true  kubectl --namespace rook-ceph get pods -l "app=rook-ceph-operator"

  kubectl delete namespace ${NAMESPACE} --ignore-not-found=true || true
  kubectl delete namespace rook-ceph-external --ignore-not-found=true || true
  sleep 15

  echo "Enabling rook-ceph addon..."
  #microk8s enable rook-ceph
  microk8s enable rook-ceph --rook-version v1.18.7
  #microk8s enable rook-ceph --rook-version  v1.16.2

  echo "Using microk8s helm and kubectl for verification..."
  microk8s helm ls --namespace ${NAMESPACE} || true
  microk8s kubectl --namespace ${NAMESPACE} get pods -o wide || true
  kubectl --namespace rook-ceph get pods -l "app=rook-ceph-operator"
  echo "Waiting for rook-ceph-operator pod to be Ready..."
  sleep 10
  wait_for_pod_ready "${NAMESPACE}" "app=rook-ceph-operator" "300s"


  # Optional: connect to external Ceph cluster if files provided
  CEPh_CONF="/etc/ceph/ceph.conf"
  CEPh_KEYRING="/etc/ceph/ceph.keyring"
  RBD_POOL="${K8S_ENVIRONMENT}-rbd"

  if [ -f "${CEPh_CONF}" ] && [ -f "${CEPh_KEYRING}" ]; then
    microk8s connect-external-ceph \
      --ceph-conf "${CEPh_CONF}" \
      --keyring "${CEPh_KEYRING}" \
      --rbd-pool "${RBD_POOL}" || echo "connect-external-ceph failed (ensure microk8s supports this command)."
    sleep 5
    microk8s kubectl --namespace rook-ceph-external get cephcluster || true
  else
    echo "No external Ceph conf/keyring found at ${CEPh_CONF} / ${CEPh_KEYRING}. Skipping external Ceph connection."
  fi

  echo "Waiting up to ${WAIT_SECONDS}s for rook-ceph pods to become Ready..."
  if ! microk8s kubectl wait --for=condition=Ready pod -n "${NAMESPACE}" --timeout="${WAIT_SECONDS}s" 2>/dev/null; then
    echo "Warning: not all rook-ceph pods reported Ready within timeout. Check: microk8s kubectl -n ${NAMESPACE} get pods -o wide"
  fi

  echo "Displaying rook-ceph cluster status..."
  microk8s kubectl --namespace rook-ceph-external get cephcluster || true
  microk8s kubectl --namespace rook-ceph get cephcluster || true

  echo "Listing storage classes..."
  microk8s kubectl get storageclasses || true

  echo "Patching storageclasses defaults (if present)..."
  # attempt to make ceph-rbd default and unset hostpath default if present
  microk8s kubectl patch storageclass microk8s-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}' || true
  microk8s kubectl patch storageclass ceph-rbd -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' || true

  echo "Verifying storageclasses after patch..."
  microk8s kubectl get storageclasses

  echo "Rook/Ceph setup complete."
  echo "Verify Rook and Ceph pods: microk8s kubectl -n ${NAMESPACE} get pods"
}

main "$@"
exit