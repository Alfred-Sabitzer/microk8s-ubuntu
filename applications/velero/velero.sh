#!/bin/bash
############################################################################################
#
# Install and configure Velero on MicroK8s.
#
# This script applies the YAML manifests from this directory, then installs the
# Velero and Velero UI Helm charts with values derived from environment variables.
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail

trap 'rc=$?; if [ $rc -ne 0 ]; then echo "Script failed with exit $rc" >&2; fi; exit $rc' EXIT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

on_error() {
  local rc=$?
  if [[ "$rc" -ne 0 ]]; then
    printf  '❌  Error: script failed with exit code %s\n' "$rc" >&2
  fi
}

trap on_error EXIT

die() { printf '❌  Error: %s\n' "$1" >&2; exit 1; }

retry() {
    local max_attempts=$1; shift
    local delay=$1; shift
    local attempt=1

    # echo "Executing command: $@ (max_attempts=$max_attempts, delay=${delay}s)"
    until "$@"; do
        if (( attempt >= max_attempts )); then
            echo "❌ Error: Command failed after $attempt attempts." >&2
            return 1
        fi
        
        local current_delay=$(( attempt * delay ))
        echo "⚠️ Command failed. Retrying $attempt of $max_attempts. Waiting ${current_delay}s..." >&2
        sleep "${current_delay}s"  # Exponential backoff
        
        ((attempt++))
    done
}


require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

require_command envsubst
require_command sudo
require_command microk8s

KUBECTL="sudo microk8s kubectl"
HELM="sudo microk8s helm"
export NAMESPACE="${VELERO_NAMESPACE:-velero}"
export VELERO_UI_NAMESPACE="${VELERO_UI_NAMESPACE:-velero-ui}"
export K8S_ENVIRONMENT="${K8S_ENVIRONMENT:-test}"
export VELERO_BACKUP_LOCATION_NAME="${VELERO_BACKUP_LOCATION_NAME:-${K8S_ENVIRONMENT}-velero}"
export VELERO_BUCKET_NAME="${VELERO_BUCKET_NAME:-${K8S_ENVIRONMENT}-velero}"
export VELERO_UI_HOST="${VELERO_UI_HOST:-velero-ui.${K8S_ENVIRONMENT}.slainte.at}"
export S3_ENDPOINT="${S3_ENDPOINT:-http://192.168.0.194:8081}"
export S3_REGION="${S3_REGION:-default}"
export VELERO_CLOUD_CREDENTIALS_BASE64=$(echo "not-set" | base64 -w 0)

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

echo "Uninstalling any existing Velero release..."
$HELM uninstall velero --namespace "$NAMESPACE" --ignore-not-found=true
$HELM uninstall otwld --namespace "$NAMESPACE" --ignore-not-found=true

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

# Reinstall Velero Helm chart
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

# get info from the secret
VELERO_SECRET_NAME=$(sudo microk8s kubectl get secret -n "$NAMESPACE" | grep velero-s3-credentials | awk '{print $1}')
VELERO_SECRET_KEY=$(sudo microk8s kubectl get secret "$VELERO_SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data.BucketInfo}' | base64 --decode)

VELERO_BUCKET_NAME=$(jq -r '.spec.bucketName' <<< "$VELERO_SECRET_KEY")
VELERO_ENDPOINT=$(jq -r '.spec.secretS3.endpoint' <<< "$VELERO_SECRET_KEY")
VELERO_BACKUP_LOCATION_NAME="${VELERO_BUCKET_NAME}"

VELERO_ACCESS_KEY=$(jq -r '.spec.secretS3.accessKeyID' <<< "$VELERO_SECRET_KEY")
VELERO_SECRET_KEY=$(jq -r '.spec.secretS3.accessSecretKey' <<< "$VELERO_SECRET_KEY")

cat <<EOF > /tmp/velero-credentials
[default]
aws_access_key_id=$VELERO_ACCESS_KEY
aws_secret_access_key=$VELERO_SECRET_KEY
EOF

export VELERO_CLOUD_CREDENTIALS_BASE64=$(base64 -w 0 /tmp/velero-credentials)

${KUBECTL} delete backupstoragelocations.velero.io -n velero test-velero 

# Reinstall Velero Helm chart
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

$HELM repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts
$HELM repo add otwld https://helm.otwld.com/
$HELM repo update

echo "Installing Velero Helm chart..."
# helm fetch vmware-tanzu/velero --untar

$HELM upgrade -i velero vmware-tanzu/velero \
    --namespace "$NAMESPACE" \
    --create-namespace \
    --wait \
    --set credentials.useSecret=true \
    --set credentials.existingSecret=velero \
    --set initContainers[0].name=velero-plugin-for-aws \
    --set initContainers[0].image=velero/velero-plugin-for-aws:latest \
    --set initContainers[0].volumeMounts[0].mountPath=/target \
    --set initContainers[0].volumeMounts[0].name=plugins \
    --set configuration.defaultVolumesToFsBackup=true \
    --set configuration.features=EnableCSI \
    --set configuration.backupStorageLocation[0].name="$VELERO_BACKUP_LOCATION_NAME" \
    --set configuration.backupStorageLocation[0].provider=aws \
    --set configuration.backupStorageLocation[0].bucket="$VELERO_BUCKET_NAME" \
    --set configuration.backupStorageLocation[0].default=true \
    --set configuration.backupStorageLocation[0].credential.name=velero \
    --set configuration.backupStorageLocation[0].credential.key=cloud \
    --set configuration.backupStorageLocation[0].config.region="$S3_REGION" \
    --set configuration.backupStorageLocation[0].config.s3ForcePathStyle="true" \
    --set configuration.backupStorageLocation[0].config.s3Url="$S3_ENDPOINT" \
    --set configuration.volumeSnapshotLocation[0].config.region="$S3_REGION" \
    --set configuration.volumeSnapshotLocation[0].name="$VELERO_BACKUP_LOCATION_NAME" \
    --set configuration.volumeSnapshotLocation[0].provider=csi \
    --set configuration.volumeSnapshotLocation[0].credential.name=velero \
    --set configuration.volumeSnapshotLocation[0].credential.key=cloud \
    --set configuration.volumeSnapshotLocation[0].config.region="$S3_REGION" \
    --set configuration.volumeSnapshotLocation[0].config.s3ForcePathStyle="true" \
    --set configuration.volumeSnapshotLocation[0].config.s3Url="$S3_ENDPOINT" \
    --set podDisruptionBudget.enabled=true \
    --set deployNodeAgent=true

# Update the Velero repository credentials secret with a new password
export VELERO_REPOSITORY_CREDENTIALS_BASE64=$(head -c 32 /dev/urandom | base64)
${KUBECTL} patch secret velero-repo-credentials -n "$NAMESPACE" --type merge -p "{\"stringData\":{\"repository-password\":\"${VELERO_REPOSITORY_CREDENTIALS_BASE64}\"}}"


# https://velero-ui.docs.otwld.com/getting-started/kubernetes

echo "###########################"
echo "Installing Velero UI Helm chart..."

cat <<EOF > /tmp/velero-ui-values.yaml
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

$HELM install velero-ui otwld/velero-ui \
    --namespace "$VELERO_UI_NAMESPACE" \
    --create-namespace \
    --wait \
    --set configuration.general.secretPassPhrase.useSecret=true \
    --set configuration.general.secretPassPhrase.value="$(head -c 32 /dev/urandom | base64)" \
    --set configuration.general.secretPassPhrase.name="velero-ui-passphrase" \
    --set autoscaling.enabled=true \
    -f /tmp/velero-ui-values.yaml

# Re-apply the YAML files to ensure everything is configured correctly.
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
