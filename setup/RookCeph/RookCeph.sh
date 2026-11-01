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

# Delete Namespace Finalizers
delete_namespace() {
    IFS=" "
    local mynamespace="${1}"
    while read api
    do
        # echo "Checking $api in namespace ${mynamespace}..."
        while read NAMEITEM AGE
        do
            #echo "deleting ${NAMEITEM}"
            # patch finalizers:
            sudo kubectl patch ${api}/${NAMEITEM} -n ${mynamespace} \
                -p '{"metadata":{"finalizers":[]}}' --type=merge || true
            # Remove Namespace Finalizers
            #kubectl get namespace ${mynamespace} -o json \
            #| jq 'del(.spec.finalizers)' \
            #| kubectl replace --raw "/api/v1/namespaces/${mynamespace}/finalize" -f -
            # Clean Up Stuck Resources
            #echo "kubectl delete ${api} -sn ${mynamespace} ${NAMEITEM} --ignore-not-found"
            sudo kubectl delete ${api} -n ${mynamespace} ${NAMEITEM} --ignore-not-found || true
        done < <(sudo kubectl get -n ${mynamespace} $api --ignore-not-found  | grep -v NAME )
    done < <(sudo kubectl api-resources --verbs=list --namespaced -o name | grep -v NAME | grep -v events)
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

# This is from /var/snap/microk8s/common/addons/core/addons/rook-ceph/plugin/rook-import-external-cluster.sh
CEPHFS_STORAGE_CLASS_NAME="cephfs"
OPERATOR_NAMESPACE="rook-ceph" # default set to rook-ceph
CSI_DRIVER_NAME_PREFIX=${CSI_DRIVER_NAME_PREFIX:-$OPERATOR_NAMESPACE}
RBD_PROVISIONER=$CSI_DRIVER_NAME_PREFIX".rbd.csi.ceph.com"       # csi-provisioner-name
CEPHFS_PROVISIONER=$CSI_DRIVER_NAME_PREFIX".cephfs.csi.ceph.com" # csi-provisioner-name

CLUSTER_ID_CEPHFS=$external_namespace
CEPHFS_CLIENT_PROFILE_NAME="rook-ceph-external"

function importCsiCephFSNodeSecret() {
  userID="$CSI_CEPHFS_NODE_SECRET_NAME"
  if ! $KUBECTL -n "$external_namespace" get secret "rook-$CSI_CEPHFS_NODE_SECRET_NAME" &>/dev/null; then
    $KUBECTL -n "$external_namespace" \
      create \
      secret \
      generic \
      --type="kubernetes.io/rook" \
      "rook-""$CSI_CEPHFS_NODE_SECRET_NAME" \
      --from-literal=userID="$userID" \
      --from-literal=userKey="$CSI_CEPHFS_NODE_SECRET"
  else
    echo "secret 'rook-$CSI_CEPHFS_NODE_SECRET_NAME' already exists"
      $KUBECTL -n "$external_namespace" \
      patch \
      secret \
      "rook-$CSI_CEPHFS_NODE_SECRET_NAME" \
      -p "{\"stringData\":{\"userID\":\"$userID\",\"userKey\":\"$CSI_CEPHFS_NODE_SECRET\"}}"
    fi
}

function importCsiCephFSProvisionerSecret() {
  userID="$CSI_CEPHFS_PROVISIONER_SECRET_NAME"
  if ! $KUBECTL -n "$external_namespace" get secret "rook-$CSI_CEPHFS_PROVISIONER_SECRET_NAME" &>/dev/null; then
    $KUBECTL -n "$external_namespace" \
      create \
      secret \
      generic \
      --type="kubernetes.io/rook" \rook-ceph-external
      "rook-""$CSI_CEPHFS_PROVISIONER_SECRET_NAME" \
      --from-literal=userID="$userID" \
      --from-literal=userKey="$CSI_CEPHFS_PROVISIONER_SECRET"
  else
    echo "secret 'rook-$CSI_CEPHFS_PROVISIONER_SECRET_NAME' already exists"
    $KUBECTL -n "$external_namespace" \
      patch \
      secret \
      "rook-$CSI_CEPHFS_PROVISIONER_SECRET_NAME" \
      -p "{\"stringData\":{\"userID\":\"$userID\",\"userKey\":\"$CSI_CEPHFS_PROVISIONER_SECRET\"}}"
  firook-ceph-external
}

function createCephFSStorageClass() {
  if ! $KUBECTL -n "$external_namespace" get storageclass $CEPHFS_STORAGE_CLASS_NAME &>/dev/null; then
    cat <<eof | $KUBECTL create -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: $CEPHFS_STORAGE_CLASS_NAME
provisioner: $CEPHFS_PROVISIONER
parameters:
  clusterID: $CLUSTER_ID_CEPHFS
  fsName: $CEPHFS_FS_NAME
  pool: $CEPHFS_POOL_NAME
  csi.storage.k8s.io/provisioner-secret-name: "rook-$CSI_CEPHFS_PROVISIONER_SECRET_NAME"
  csi.storage.k8s.io/provisioner-secret-namespace: $external_namespace
  csi.storage.k8s.io/controller-expand-secret-name: "rook-$CSI_CEPHFS_PROVISIONER_SECRET_NAME"
  csi.storage.k8s.io/controller-expand-secret-namespace: $external_namespace
  csi.storage.k8s.io/node-stage-secret-name: "rook-$CSI_CEPHFS_NODE_SECRET_NAME"
  csi.storage.k8s.io/node-stage-secret-namespace: $external_namespace
allowVolumeExpansion: true
reclaimPolicy: Delete
eof
  else
    echo "storageclass $CEPHFS_STORAGE_CLASS_NAME already exists"
  fi
}

function createCephClientProfile() {
  if ! $KUBECTL -n "$external_namespace" get clientprofile $CEPHFS_CLIENT_PROFILE_NAME &>/dev/null; then
    cat <<eof | $KUBECTL create -f -
apiVersion: csi.ceph.io/v1
kind: ClientProfile
metadata:
  name: $external_namespace
  namespace: $NAMESPACE
spec:
  cephConnectionRef:
    name: $external_namespace
  cephFs:
    kernelMountOptions:
      ms_mode: crc
    cephCsiSecrets:
      controllerPublishSecret:
        name: $CEPHFS_PROVISIONER
        namespace: $external_namespace
  rbd:
    cephCsiSecrets:
      controllerPublishSecret:
        name: $RBD_PROVISIONER
        namespace: $external_namespace
eof
  else
    echo "clientprofile $CEPHFS_CLIENT_PROFILE_NAME already exists"
  fi
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
  sudo helm uninstall rook-ceph-external -n ${external_namespace} --ignore-not-found --timeout 300s 
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

  # helm -n rook-ceph get values rook-ceph
  # helm -n rook-ceph get manifest rook-ceph
  # helm get all -n rook-ceph rook-ceph 

  echo "Enabling rook-ceph addon..."
  sudo microk8s enable rook-ceph \
    --rook-version v1.18.7 \
    --set cosi.enabled=true \
    --set csi.kubeletDirPath=/var/snap/microk8s/common/var/lib/kubelet \
    --set csi.serviceMonitor.enabled=true \
    --set csi.serviceMonitor.additionalLabels.release=release:kube-prom-stack 

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

  source /etc/ceph/vars_${K8S_ENVIRONMENT}.sh
  
  sudo microk8s connect-external-ceph \
    --ceph-conf "${CEPh_CONF}" \
    --keyring "${CEPh_KEYRING}" \
    --rbd-pool "${RBD_POOL}" \
    --namespace rook-ceph-external

  #sudo microk8s kubectl wait --for=condition=Ready pod --all -n "${external_namespace}" --timeout="300s"

  echo ""
  echo "Check created cluster in k8s cluster namespace '${external_namespace}'"
  echo ""
  sudo microk8s kubectl get cephcluster -n ${external_namespace}

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

  if [ -n "$CSI_CEPHFS_NODE_SECRET_NAME" ] && [ -n "$CSI_CEPHFS_NODE_SECRET" ]; then
    importCsiCephFSNodeSecret
  fi
  if [ -n "$CSI_CEPHFS_PROVISIONER_SECRET_NAME" ] && [ -n "$CSI_CEPHFS_PROVISIONER_SECRET" ]; then
    importCsiCephFSProvisionerSecret
  fi
  if [ -n "$CEPHFS_FS_NAME" ] && [ -n "$CEPHFS_POOL_NAME" ]; then
    createCephFSStorageClass
  fi

  createCephClientProfile

# # Patch the rook-ceph-mon-endpoints configmap to set kernelMountOptions for CephFS
#   sudo microk8s kubectl get configmap rook-ceph-mon-endpoints \
#     -n rook-ceph-external -o json |
#   jq '
#     .data["csi-cluster-config-json"] |=
#     (
#       fromjson |
#       .[0].cephFS.kernelMountOptions = "ms_mode=crc" |
#       tojson
#     )
#   ' |
#   sudo microk8s kubectl apply -f -

# # Patch the rook-ceph-csi-config configmap to set kernelMountOptions for CephFS
#   sudo microk8s kubectl patch configmap ceph-csi-config \
#     -n rook-ceph \
#     --type merge \
#     -p "$(sudo microk8s kubectl get configmap ceph-csi-config \
#       -n rook-ceph -o json |
#       jq -c '
#         .data["config.json"] |=
#         (fromjson |
#         map(if .clusterID == "rook-ceph-external"
#             then .cephFS.kernelMountOptions = "ms_mode=crc"
#             else . end) |
#         tojson)
#       ' |
#       jq -Rs '{data: {"config.json": .}}')"

# kubectl -n rook-ceph-external exec deploy/rook-ceph-tools -- ceph status
# kubectl -n rook-ceph-external exec deploy/rook-ceph-tools -- ceph fs status

  sudo microk8s kubectl get all -n ${NAMESPACE}

  echo "Patching storageclasses defaults (if present)..."
  # attempt to make ceph-rbd default and unset hostpath default if present
  sudo microk8s kubectl patch storageclass microk8s-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}' || true
  sudo microk8s kubectl patch storageclass ceph-rbd -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' || true

  echo "Verifying storageclasses after patch..."
  sudo microk8s kubectl get storageclasses

  echo "Verifying cephcluster in external namespace '${external_namespace}'..."
  sudo microk8s kubectl get -n rook-ceph-external cephcluster

  echo "Verify Rook and Ceph pods: sudo microk8s kubectl -n ${NAMESPACE} get pods"
  sudo microk8s kubectl -n ${NAMESPACE} get pods

  sudo microk8s kubectl get clientprofile ${external_namespace} -n ${NAMESPACE} \
  -o jsonpath='{.spec.cephFs.kernelMountOptions}{"\n"}'

  sudo microk8s kubectl get configmap ceph-csi-config -n ${NAMESPACE} \
    -o jsonpath='{.data.config\.json}' | jq .

cat <<EOF
#
# Verify the ceph-csi-config configmap in the rook-ceph namespace:
#
# iMPORTANT: The configmap should show the kernelMountOptions set to "ms_mode=crc" for the rook-ceph-external cluster.
#
ansible@k8stest:~$ k get cm -n rook-ceph ceph-csi-config -o yaml
apiVersion: v1
data:
  config.json: |
    [{"clusterID":"rook-ceph-external","monitors":["192.168.0.194:3300","192.168.0.191:3300","192.168.0.192:3300"],"cephFS":{"kernelMountOptions":"ms_mode=crc","fuseMountOptions":"","controllerPublishSecretRef":{"name":"rook-csi-cephfs-provisioner","namespace":"rook-ceph-external"}},"rbd":{"controllerPublishSecretRef":{"name":"rook-csi-rbd-provisioner","namespace":"rook-ceph-external"}},"nfs":{},"readAffinity":{}}]
kind: ConfigMap
metadata:
  creationTimestamp: "2026-11-01T10:11:40Z"
  name: ceph-csi-config
  namespace: rook-ceph
  ownerReferences:
  - apiVersion: csi.ceph.io/v1
    kind: Driver
    name: rook-ceph.rbd.csi.ceph.com
    uid: e6f4b1c3-0d3e-46b2-bea4-bff85f7efc96
  - apiVersion: csi.ceph.io/v1
    kind: Driver
    name: rook-ceph.cephfs.csi.ceph.com
    uid: 6da42eb1-c688-4682-b4f8-d1b1d29bda26
  - apiVersion: csi.ceph.io/v1
    kind: ClientProfile
    name: rook-ceph-external
    uid: c25c29ad-df15-4727-b99e-826296ebf11f
  resourceVersion: "92550069"
  uid: 396693b3-c80e-4a5b-aa93-e6add9fc9740


# after changing the configmap, restart the rook-ceph-cephfs-csi plugin deployment to apply the changes:

k rollout restart deployment \
  rook-ceph.cephfs.csi.ceph.com-ctrlplugin \
  -n rook-ceph
EOF

  echo "Rook/Ceph setup complete."
}

main "$@"
exit