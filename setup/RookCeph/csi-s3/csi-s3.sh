#!/bin/bash
############################################################################################
#
# Install and configure csi-s3 on MicroK8s.
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail

trap 'rc=$?; if [ $rc -ne 0 ]; then echo "Script failed with exit $rc" >&2; fi; exit $rc' EXIT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

die() {
  echo "Error: $*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

retry() {
  local attempts=$1
  shift
  local delay=$1
  shift
  local i
  for i in $(seq 1 "$attempts"); do
    if "$@"; then
      return 0
    fi
    echo "Attempt ${i}/${attempts} failed. Retrying in ${delay}s..."
    sleep "$delay"
  done
  return 1
}

require_command envsubst
require_command sudo
require_command microk8s

KUBECTL="sudo microk8s kubectl"
HELM="sudo microk8s helm"
export NAMESPACE="${VELERO_NAMESPACE:-csi-s3}"
export K8S_ENVIRONMENT="${K8S_ENVIRONMENT:-test}"
export S3_ENDPOINT="${S3_ENDPOINT:-http://192.168.0.194:8081}"
export S3_REGION="${S3_REGION:-default}"
export S3_SECRET="rook-ceph-object-user-external-store-csi-s3"

RETRY_ATTEMPTS=5
RETRY_DELAY=5

# shellcheck disable=SC2155
export ENV_SUBST_VARS="$(env | cut -d'=' -f1 | paste -sd ' ' -)"

echo ""
echo "Finding YAML files in $SCRIPT_DIR..."
mapfile -t yamls < <(find "$SCRIPT_DIR" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort -r)

if [ "${#yamls[@]}" -eq 0 ]; then
  echo "INFO: No YAML files found in $SCRIPT_DIR"
  exit 0
fi

echo "Uninstalling any existing csi-s3 release..."
$HELM uninstall csi-s3 --namespace "$NAMESPACE" --ignore-not-found=true

echo "Found ${#yamls[@]} YAML file(s)."
echo ""
echo "========== delete YAML Resources =========="
for f in "${yamls[@]}"; do
  echo ""
  echo "Deleting: $f"
  if ! retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < "$f" | $KUBECTL delete --ignore-not-found=true -f -; then
    die "Failed to delete resources from $f after $RETRY_ATTEMPTS attempts"
  fi
done

# Reinstall csi-s3 Helm chart
mapfile -t yamls < <(find "$SCRIPT_DIR" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort)
echo "Found ${#yamls[@]} YAML file(s)."
echo ""
echo "========== apply YAML Resources =========="
for f in "${yamls[@]}"; do
  echo ""
  echo "Applying: $f"
  if ! retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < "$f" | $KUBECTL apply -f -; then
    die "Failed to apply $f after $RETRY_ATTEMPTS attempts"
  fi
done

$HELM repo add k8s-csi-s3 https://yandex-cloud.github.io/k8s-csi-s3/charts
$HELM repo update

echo "Installing csi-s3 Helm chart..."
# helm fetch k8s-csi-s3/csi-s3 --untar

# https://artifacthub.io/packages/helm/k8s-csi-s3/csi-s3
$KUBECTL delete storageclass csi-s3 --ignore-not-found=true
$KUBECTL delete clusterrole.rbac.authorization.k8s.io csi-s3 --ignore-not-found=true
$KUBECTL delete clusterrole.rbac.authorization.k8s.io csi-s3-external-provisioner-runner --ignore-not-found=true
$KUBECTL delete ClusterRoleBinding csi-s3 --ignore-not-found=true
$KUBECTL delete ClusterRoleBinding csi-s3-provisioner-role --ignore-not-found=true
$KUBECTL delete CSIDriver ru.yandex.s3.csi --ignore-not-found=true

$HELM upgrade -i csi-s3 k8s-csi-s3/csi-s3 \
    --namespace "$NAMESPACE" \
    --create-namespace \
    --wait \
    --set kubeletDir=/var/snap/microk8s/common/var/lib/kubelet \
    --set secret.create=false \
    --set secret.name="$S3_SECRET" \
    --set secret.accessKey="AccessKey" \
    --set secret.secretKey="SecretKey" \
    --set secret.endpoint="Endpoint"

exit

#####
Parameter	Description	Default
storageClass.create	Specifies whether the storage class should be created	true
storageClass.name	Storage class name	csi-s3
storageClass.singleBucket	Use a single bucket for all dynamically provisioned persistent volumes	
storageClass.mounter	Mounter to use. Either geesefs, s3fs or rclone. geesefs recommended	geesefs
storageClass.mountOptions	GeeseFS mount options	--memory-limit 1000 --dir-mode 0777 --file-mode 0666
storageClass.reclaimPolicy	Volume reclaim policy	Delete
storageClass.annotations	Annotations for the storage class	
secret.create	Specifies whether the secret should be created	true
secret.name	Name of the secret	csi-s3-secret
secret.accessKey	S3 Access Key	
secret.secretKey	S3 Secret Key	
secret.endpoint	Endpoint	
secret.region	Region	
tolerations.all	Tolerate all taints by the CSI-S3 node driver (mounter)	false
tolerations.node	Custom tolerations for the CSI-S3 node driver (mounter)	[]
tolerations.controller	Custom tolerations for the CSI-S3 controller (provisioner)	[]