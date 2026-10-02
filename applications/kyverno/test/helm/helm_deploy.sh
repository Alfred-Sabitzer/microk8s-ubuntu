#!/usr/bin/env bash
############################################################################################
#
# Build and deploy the Kyverno test workload via Helm.
#
# Usage:
#   ./helm_deploy.sh [ENV_FILE]
#
# The env file should export HARBOR_LINK, build, tag, project, image and digest.
############################################################################################
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage: ./helm_deploy.sh [ENV_FILE]

Deploy the Kyverno test chart into the selected namespace.

Optional overrides:
  TARGET_NAMESPACE   Default: kyverno-test
  HELM_CMD           Default: helm
  KUBECTL_CMD        Auto-detected: kubectl or microk8s kubectl

Example:
  ./helm_deploy.sh ./podman_kyverno-test_dummy_20261001.env
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

env_file="${1:-${HELM_ENV_FILE:-./podman_kyverno-test_dummy_20261001.env}}"
if [[ ! -f "${env_file}" ]]; then
  printf 'Error: environment file not found: %s\n' "${env_file}" >&2
  usage >&2
  exit 1
fi

# shellcheck disable=SC1090
source "${env_file}"

: "${HARBOR_LINK:?HARBOR_LINK must be set in ${env_file}}"
: "${build:?build must be set in ${env_file}}"
: "${tag:?tag must be set in ${env_file}}"
: "${project:?project must be set in ${env_file}}"
: "${image:?image must be set in ${env_file}}"
: "${digest:?digest must be set in ${env_file}}"

TARGET_NAMESPACE="${TARGET_NAMESPACE:-kyverno-test}"
RELEASE_NAME="${RELEASE_NAME:-${image}}"

if command -v kubectl >/dev/null 2>&1; then
  KUBECTL_CMD="${KUBECTL_CMD:-kubectl}"
elif command -v microk8s >/dev/null 2>&1; then
  if command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
    KUBECTL_CMD="${KUBECTL_CMD:-sudo microk8s kubectl}"
  else
    KUBECTL_CMD="${KUBECTL_CMD:-microk8s kubectl}"
  fi
else
  printf 'Error: neither kubectl nor microk8s is available in PATH.\n' >&2
  exit 1
fi

if command -v helm >/dev/null 2>&1; then
  HELM_CMD="${HELM_CMD:-helm}"
else
  printf 'Error: helm is not available in PATH.\n' >&2
  exit 1
fi

read -r -a kubectl_cmd <<< "${KUBECTL_CMD}"
if ! "${kubectl_cmd[@]}" version --client >/dev/null 2>&1; then
  printf 'Error: Kubernetes client command failed: %s\n' "${KUBECTL_CMD}" >&2
  exit 1
fi

read -r -a helm_cmd <<< "${HELM_CMD}"
if ! "${helm_cmd[@]}" version --short >/dev/null 2>&1; then
  printf 'Error: Helm command failed: %s\n' "${HELM_CMD}" >&2
  exit 1
fi

printf 'Uninstalling previous Helm release %s in namespace %s...\n' "${RELEASE_NAME}" "${TARGET_NAMESPACE}"
"${helm_cmd[@]}" uninstall "${RELEASE_NAME}" --namespace "${TARGET_NAMESPACE}" --wait --ignore-not-found=true || true

printf 'Installing Helm release %s in namespace %s...\n' "${RELEASE_NAME}" "${TARGET_NAMESPACE}"
"${helm_cmd[@]}" upgrade --install "${RELEASE_NAME}" ./ \
  --namespace "${TARGET_NAMESPACE}" \
  --create-namespace \
  --set buildInfo.tool="${build}" \
  --set image.registry="${HARBOR_LINK}" \
  --set image.project="${project}" \
  --set image.repository="${image}" \
  --set image.tag="${tag}" \
  --set image.digest="${digest}"