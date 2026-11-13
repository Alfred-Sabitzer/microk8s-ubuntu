#!/bin/bash
############################################################################################
#
# build and deploy via Helm
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
shopt -o -s nounset #-No Variables without definition

KUBECTL_CMD="kubectl"
HELM_CMD="helm"

export TARGET_NAMESPACE="duplicity"

source $1

helm upgrade --install $image ./ \
  --create-namespace \
  --set namespace="${TARGET_NAMESPACE}" \
  --set image.registry="${HARBOR_LINK}" \
  --set buildInfo.tool="${build}" \
  --set image.tag="${tag}" \
  --set image.project="${project}" \
  --set image.repository="${image}" \
  --set image.digest="${digest}"

# helm uninstall --ignore-not-found $image


