#!/bin/bash
############################################################################################
#
# Install and configure Velero on MicroK8s
#
# https://vmware-tanzu.github.io/helm-charts/
# https://github.com/vmware-tanzu/helm-charts/blob/main/charts/velero/README.md
# https://medium.com/@himanshurahangdale153/velero-for-backup-restore-of-kubernetes-clusters-1b71408fb8f3
# https://linbit.com/blog/using-velero-linbit-sds-to-back-up-restore-a-kubernetes-deployment/
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail

trap 'rc=$?; if [ $rc -ne 0 ]; then echo "Script failed with exit $rc" >&2; fi; exit $rc' EXIT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

die() { echo "Error: $*" >&2; exit 1; }


retry() {
  local attempts=$1; shift
  local delay=$1; shift
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

KUBECTL="sudo microk8s kubectl"
helm="sudo microk8s helm"
export NAMESPACE="velero"
K8S_ENVIRONMENT="${K8S_ENVIRONMENT:-dev}"
VELERO_UI_HOST="${VELERO_UI_HOST:-velero.${K8S_ENVIRONMENT}.slainte.at}"
WAIT_SECONDS="${WAIT_SECONDS:-180}"
RETRY_ATTEMPTS=5
RETRY_DELAY=5

echo ""
echo "Finding YAML files in $SCRIPT_DIR..."
mapfile -t yamls < <(find "$SCRIPT_DIR" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort -r)

if [ "${#yamls[@]}" -eq 0 ]; then
  echo "INFO: No YAML files found in $SCRIPT_DIR"
  exit 0
fi

echo "Found ${#yamls[@]} YAML file(s)."
echo ""
echo "========== delete YAML Resources =========="
for f in "${yamls[@]}"; do
  echo ""
  echo "Applying: $f"
  if ! retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < ${f} | $KUBECTL delete --ignore-not-found=true -f - ; then
    die "Failed to apply $f after $RETRY_ATTEMPTS attempts"
  fi
done

echo "Uninstalling any existing Velero release..."
$helm uninstall velero --namespace ${NAMESPACE} --ignore-not-found=true

# Reinstall Velero Helm chart
mapfile -t yamls < <(find "$SCRIPT_DIR" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort)
echo "Found ${#yamls[@]} YAML file(s)."
echo ""
echo "========== apply YAML Resources =========="
for f in "${yamls[@]}"; do
  echo ""
  echo "Applying: $f"
  if ! retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < ${f} | $KUBECTL apply -f - ; then
    die "Failed to apply $f after $RETRY_ATTEMPTS attempts"
  fi
done


$helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts
$helm repo update

bucket_name="${K8S_ENVIRONMENT}-velero"

echo "Installing Velero Helm chart..."
$helm upgrade -i velero vmware-tanzu/velero \
    --namespace ${NAMESPACE} \
    --wait \
    --generate-name \
    --set credentials.useSecret=true \
    --set credentials.existingSecret=velero \
    --set configuration.backupStorageLocation[0].name=${bucket_name} \
    --set configuration.backupStorageLocation[0].provider=aws \
    --set configuration.backupStorageLocation[0].bucket=${bucket_name} \
    --set configuration.backupStorageLocation[0].config.region=US


#