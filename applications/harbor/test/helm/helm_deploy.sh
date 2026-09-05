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

export TARGET_NAMESPACE="test"

# This is for testing purposes only. In production, you should use a proper image repository and tag.
#export HARBOR_LINK="http://harbor.harbor.svc.cluster.local/v2"
source ./podman_test_dummy_20260905.env
# export HARBOR_LINK="harbor.test.slainte.at"
# export build="podman"
# export tag="20260901"
# export project="test"
# export image="dummy"
# export digest="sha256:63c49e1cdae675cf9f93bd95db9625938e49811aec1e28f4b268dd3ab72bc1af"

#helm upgrade --install $image ./app-deployment \
# helm template $image ./ \
#   --create-namespace \
#   --set namespace="${TARGET_NAMESPACE}" \
#   --set image.registry="${HARBOR_LINK}" \
#   --set buildInfo.tool="${build}" \
#   --set image.tag="${tag}" \
#   --set image.project="${project}" \
#   --set image.repository="${image}" \
#   --set image.digest="${digest}" \
#   --debug \
#    > output.yaml

helm upgrade --install $image ./ \
  --create-namespace \
  --set namespace="${TARGET_NAMESPACE}" \
  --set image.registry="${HARBOR_LINK}" \
  --set buildInfo.tool="${build}" \
  --set image.tag="${tag}" \
  --set image.project="${project}" \
  --set image.repository="${image}" \
  --set image.digest="${digest}"

# curl --cert /etc/containers/certs.d/harbor.test.slainte.at/client.cert \
#      --key /etc/containers/certs.d/harbor.test.slainte.at/client.key \
#      --cacert /etc/containers/certs.d/harbor.test.slainte.at/ca.crt  \
#      -X 'GET' \
#      -H 'accept: application/json' \
#      -u "${HARBOR_USER}:${HARBOR_PASSWORD}" \
#      https://harbor.test.slainte.at/v2/test/dummy/manifests/sha256:63c49e1cdae675cf9f93bd95db9625938e49811aec1e28f4b268dd3ab72bc1af

# helm uninstall --ignore-not-found $image


