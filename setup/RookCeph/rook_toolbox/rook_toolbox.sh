#!/bin/bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
RETRY_ATTEMPTS=5
RETRY_DELAY=5
external_namespace="rook-ceph-external"
secret_file=""

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

kubectl() {
  sudo microk8s kubectl "$@"
}

retry_apply_manifest() {
  local manifest=$1
  local i
  for ((i = 1; i <= RETRY_ATTEMPTS; i++)); do
    if kubectl apply -f "$manifest"; then
      return 0
    fi
    if ((i < RETRY_ATTEMPTS)); then
      echo "Apply failed (attempt $i/$RETRY_ATTEMPTS). Retrying in ${RETRY_DELAY}s..."
      sleep "$RETRY_DELAY"
    fi
  done
  return 1
}

wait_for_pod_ready() {
  local ns=$1
  local selector=$2
  local timeout=${3:-300s}
  echo "Waiting for pods (ns=${ns}, selector=${selector}) to be Ready (timeout=${timeout})..."
  kubectl wait --for=condition=Ready pod -l "${selector}" -n "${ns}" --timeout="${timeout}"
}

main() {
  command -v sudo >/dev/null 2>&1 || die "sudo is required."

  local environment="${K8S_ENVIRONMENT:-}"
  [[ "$environment" =~ ^[A-Za-z0-9_-]+$ ]] ||
    die "Set K8S_ENVIRONMENT to a valid environment name (letters, digits, '_' or '-')."

  local vars_file="/etc/ceph/vars_${environment}.sh"
  [[ -r "$vars_file" ]] || die "Cannot read required variables file: $vars_file"
  # This file is generated from the trusted external-cluster setup and contains secret values.
  # shellcheck source=/dev/null
  source "$vars_file"

  local ceph_keyring="/etc/ceph/ceph.keyring"
  [[ -r "$ceph_keyring" ]] || die "Cannot read Ceph admin keyring: $ceph_keyring"

  local required_var
  for required_var in ROOK_EXTERNAL_FSID MONITORING_ENDPOINT MONITORING_ENDPOINT_PORT; do
    [[ -n "${!required_var:-}" ]] || die "$required_var must be set in $vars_file."
  done

  [[ "$MONITORING_ENDPOINT" =~ ^[A-Za-z0-9.-]+$ ]] ||
    die "MONITORING_ENDPOINT must be an IPv4 address or DNS hostname without a scheme or port."
  [[ "$MONITORING_ENDPOINT_PORT" =~ ^[0-9]{1,5}$ ]] ||
    die "MONITORING_ENDPOINT_PORT must be a port number from 1 to 65535."
  if ((10#$MONITORING_ENDPOINT_PORT < 1 || 10#$MONITORING_ENDPOINT_PORT > 65535)); then
    die "MONITORING_ENDPOINT_PORT must be a port number from 1 to 65535."
  fi

  local cephsecret
  cephsecret="$(awk '
    /^[[:space:]]*\[/ {
      in_admin = ($0 ~ /^[[:space:]]*\[client\.admin\][[:space:]]*$/)
    }
    in_admin && /^[[:space:]]*key[[:space:]]*=/ {
      sub(/^[^=]*=[[:space:]]*/, "")
      sub(/[[:space:]]*$/, "")
      print
      exit
    }
  ' "$ceph_keyring")"
  [[ -n "$cephsecret" ]] || die "No key entry found in the [client.admin] section of $ceph_keyring."

  secret_file="$(mktemp)" || die "Could not create a temporary file for the Ceph key."
  trap 'if [[ -n "$secret_file" ]]; then rm -f -- "$secret_file"; fi' EXIT
  printf '%s' "$cephsecret" > "$secret_file"
  unset cephsecret

  echo "Checking MicroK8s access and external Rook namespace..."
  kubectl get namespace "$external_namespace" >/dev/null
  kubectl get serviceaccount rook-ceph-default -n "$external_namespace" >/dev/null ||
    die "Required service account rook-ceph-default is missing from namespace $external_namespace."

  echo "Applying Rook Ceph admin secret..."
  kubectl create secret generic rook-ceph-admin \
    --namespace "$external_namespace" \
    --type kubernetes.io/rook \
    --from-literal=admin-secret=admin-secret \
    --from-file="ceph-secret=$secret_file" \
    --from-literal=ceph-username=client.admin \
    --from-literal=cluster-name=rook-ceph-external \
    --from-literal="fsid=$ROOK_EXTERNAL_FSID" \
    --from-literal=mon-secret=mon-secret \
    --dry-run=client -o yaml | kubectl apply -f -

  echo "Applying Rook Ceph admin endpoints configmap..."
  kubectl create configmap rook-ceph-admin-endpoints \
    --namespace "$external_namespace" \
    --from-literal="data=${MONITORING_ENDPOINT}:${MONITORING_ENDPOINT_PORT}" \
    --dry-run=client -o yaml | kubectl apply -f -

  local -a yamls=()
  mapfile -t yamls < <(find "$script_dir" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort)
  if (( ${#yamls[@]} == 0 )); then
    die "No YAML manifests found in $script_dir."
  fi

  echo "Applying ${#yamls[@]} toolbox manifest(s)..."
  local manifest
  for manifest in "${yamls[@]}"; do
    echo "Applying: $manifest"
    retry_apply_manifest "$manifest" ||
      die "Failed to apply $manifest after $RETRY_ATTEMPTS attempts."
  done

  wait_for_pod_ready "$external_namespace" "app=rook-ceph-tools" "300s"

}

main "$@"
exit