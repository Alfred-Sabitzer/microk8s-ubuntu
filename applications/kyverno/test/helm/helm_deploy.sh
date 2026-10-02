#!/bin/bash
############################################################################################
#
# build and deploy via Helm
#
############################################################################################
shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
shopt -o -s nounset #-No Variables without definition

KUBECTL_CMD="sudo kubectl"
HELM_CMD="sudo helm"
mysource="${1:-./podman_kyverno-test_dummy_20261001.env}"
export TARGET_NAMESPACE="kyverno-test"

# This is for testing purposes only. In production, you should use a proper image repository and tag.
#export HARBOR_LINK="http://harbor.harbor.svc.cluster.local/v2"
source ${mysource}

echo "Uninstalling previous Helm release ${image} in namespace ${TARGET_NAMESPACE}..."
${HELM_CMD} uninstall "${image}" --namespace "${TARGET_NAMESPACE}" --wait --ignore-not-found=true || true
echo "Installing Helm release ${image} in namespace ${TARGET_NAMESPACE}..."
${HELM_CMD} upgrade --install "${image}" ./ \
  --namespace "${TARGET_NAMESPACE}" \
  --set buildInfo.tool="${build}" \
  --set image.registry="${HARBOR_LINK}" \
  --set image.tag="${tag}" \
  --set image.project="${project}" \
  --set image.repository="${image}" \
  --set image.digest="${digest}"