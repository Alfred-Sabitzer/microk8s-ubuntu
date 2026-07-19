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
K8S_ENVIRONMENT="${K8S_ENVIRONMENT:-test}"
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

echo "Uninstalling any existing Velero release..."
$helm uninstall velero --namespace ${NAMESPACE} --ignore-not-found=true
$helm uninstall otwld --namespace ${NAMESPACE} --ignore-not-found=true

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
$helm repo add otwld https://helm.otwld.com/
$helm repo update

bucket_name="${K8S_ENVIRONMENT}-velero"

echo "Installing Velero Helm chart..."
# helm fetch vmware-tanzu/velero --untar

$helm upgrade -i velero vmware-tanzu/velero \
    --namespace ${NAMESPACE} \
    --create-namespace \
    --wait \
    --set credentials.useSecret=true \
    --set credentials.existingSecret=velero \
    --set initContainers[0].name=velero-plugin-for-aws \
    --set initContainers[0].image=velero/velero-plugin-for-aws:latest \
    --set initContainers[0].volumeMounts[0].mountPath=/target \
    --set configuration.defaultVolumesToFsBackup=true \
    --set configuration.features=EnableCSI \
    --set configuration.backupStorageLocation[0].name=${bucket_name} \
    --set configuration.backupStorageLocation[0].provider=aws \
    --set configuration.backupStorageLocation[0].bucket=${bucket_name} \
    --set configuration.backupStorageLocation[0].default=true \
    --set configuration.backupStorageLocation[0].credential.name=velero \
    --set configuration.backupStorageLocation[0].credential.key=cloud \
    --set configuration.backupStorageLocation[0].config.region=default \
    --set configuration.backupStorageLocation[0].config.s3ForcePathStyle="true" \
    --set configuration.backupStorageLocation[0].config.s3Url=http://192.168.0.194:8081 \
    --set configuration.volumeSnapshotLocation[0].config.region=default \
    --set configuration.volumeSnapshotLocation[0].name=${bucket_name} \
    --set configuration.volumeSnapshotLocation[0].provider=csi \
    --set configuration.volumeSnapshotLocation[0].credential.name=velero \
    --set configuration.volumeSnapshotLocation[0].credential.key=cloud \
    --set configuration.volumeSnapshotLocation[0].config.region=default \
    --set configuration.volumeSnapshotLocation[0].config.s3ForcePathStyle="true" \
    --set configuration.volumeSnapshotLocation[0].config.s3Url=http://192.168.0.194:8081 \
    --set initContainers[0].volumeMounts[0].name=plugins


# https://velero-ui.docs.otwld.com/getting-started/kubernetes

echo "###########################"
echo "Installing Velero UI Helm chart..."

cat << EOF > /tmp/velero-ui-values.yaml
# values.yaml
env:
  - name: BASIC_AUTH_USERNAME
    valueFrom:
      secretKeyRef:
        name: velero-ui
        key: username
  - name: BASIC_AUTH_PASSWORD
    valueFrom:
      secretKeyRef:
        name: velero-ui
        key: password
EOF

$helm install velero-ui otwld/velero-ui \
    --namespace velero-ui \
    --create-namespace \
    --wait \
    --set configuration.general.secretPassPhrase.useSecret=true \
    --set configuration.general.secretPassPhrase.existingSecret=velero-ui \
    -f /tmp/velero-ui-values.yaml

# for sure, we can reapply the YAML files to ensure everything is configured correctly
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


#