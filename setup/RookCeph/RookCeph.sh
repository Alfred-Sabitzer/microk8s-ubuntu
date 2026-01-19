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

source /etc/ceph/vars_${K8S_ENVIRONMENT}.sh
export external_namespace="rook-ceph-external"

# Delete Namespace Finalizers
delete_namespace() {
    IFS=" "
    local mynamespace="${1}"
    while read api
    do
        # echo "Checking $api in namespace ${mynamespace}..."
        while read NAMEITEM AGE
        do
            echo "deleting ${NAMEITEM}"
            # patch finalizers:
            sudo kubectl patch ${api}/${NAMEITEM} -n ${mynamespace} \
                -p '{"metadata":{"finalizers":[]}}' --type=merge
            # Remove Namespace Finalizers
            #kubectl get namespace ${mynamespace} -o json \
            #| jq 'del(.spec.finalizers)' \
            #| kubectl replace --raw "/api/v1/namespaces/${mynamespace}/finalize" -f -
            # Clean Up Stuck Resources
            echo "kubectl delete ${api} -n ${mynamespace} ${NAMEITEM} --ignore-not-found"
            sudo kubectl delete ${api} -n ${mynamespace} ${NAMEITEM} --ignore-not-found
        done < <(sudo kubectl get -n ${mynamespace} $api --ignore-not-found  | grep -v NAME )
    done < <(sudo kubectl api-resources --verbs=list --namespaced -o name | grep -v NAME )
}
#
# Cleanup any previous installs
#

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

  echo ""
  sudo helm uninstall rook-ceph -n ${NAMESPACE} --ignore-not-found --timeout 300s 
  sudo helm uninstall rook-ceph-cluster -n ${external_namespace} --ignore-not-found --timeout 300s 
  echo ""  

  echo "Adding/updating rook helm repo (local helm wrapper) and updating..."
 # sudo microk8s helm repo add rook-release https://charts.rook.io/stable || true
  sudo microk8s helm repo update || true
  
  echo "Disabling rook-ceph (clean start)..."
  sudo microk8s disable rook-ceph --force || true  

  echo ""
  echo "delete namespace '${NAMESPACE}'"
  echo ""
  delete_namespace ${NAMESPACE}
  sudo microk8s kubectl delete namespace ${NAMESPACE} --force --timeout 300s --ignore-not-found || true
  echo ""
  echo "delete namespace '${external_namespace}'"
  delete_namespace ${external_namespace}
  sudo microk8s kubectl delete namespace ${external_namespace}  --force --timeout 300s --ignore-not-found=true || true
  echo ""
  sudo microk8s kubectl delete storageclass ceph-rbd --ignore-not-found
  sudo microk8s kubectl delete storageclass cephfs --ignore-not-found
  sleep 15

  echo "Enabling rook-ceph addon..."
  sudo microk8s enable rook-ceph
  #sudo microk8s enable rook-ceph --rook-version v1.18.7
  #sudo microk8s enable rook-ceph --rook-version  v1.16.2

  echo "Using sudo microk8s helm and kubectl for verification..."
  sudo microk8s helm ls --namespace ${NAMESPACE} || true
  sudo microk8s kubectl --namespace ${NAMESPACE} get pods -o wide || true
  sudo microk8s kubectl --namespace rook-ceph get pods -l "app=rook-ceph-operator"
  echo "Waiting for rook-ceph-operator pod to be Ready..."
  sleep 10
  wait_for_pod_ready "${NAMESPACE}" "app=rook-ceph-operator" "300s"

  echo ""
  echo "install rook-ceph-cluster '${external_namespace}'"
  echo ""
  # Optional: connect to external Ceph cluster if files provided
  CEPh_CONF="/etc/ceph/ceph.conf"
  CEPh_KEYRING="/etc/ceph/ceph.keyring"
  RBD_POOL="${K8S_ENVIRONMENT}-rbd"

  sudo microk8s connect-external-ceph \
    --ceph-conf "${CEPh_CONF}" \
    --keyring "${CEPh_KEYRING}" \
    --rbd-pool "${RBD_POOL}"

  sudo microk8s kubectl wait --for=condition=Ready pod --all -n "${external_namespace}" --timeout="300s"

  echo ""
  echo "Check created cluster in k8s cluster namespace '${external_namespace}'"
  echo ""
  sudo microk8s kubectl get cephcluster -n ${external_namespace}

  echo ""
  echo "Finding YAML files in $target_dir..."
  mapfile -t yamls < <(find "$target_dir" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort)

  if [ "${#yamls[@]}" -eq 0 ]; then
    echo "INFO: No YAML files found in $target_dir"
    exit 0
  fi

  echo "Found ${#yamls[@]} YAML file(s)."
  echo ""
  echo "========== Applying YAML Resources =========="
  for f in "${yamls[@]}"; do
    echo ""
    echo "Applying: $f"
    if ! retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" apply_file "$f" ; then
      die "Failed to apply $f after $RETRY_ATTEMPTS attempts"
    fi
  done

  echo ""
  echo "Check created resources in k8s cluster namespace '${NAMESPACE}'"
  echo ""
  sudo microk8s kubectl get all -n ${NAMESPACE}

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