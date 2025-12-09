#!/bin/bash
################################################################################
#
# Install Bookinfo sample application into MicroK8s.
#
# See https://istio.io/latest/docs/examples/bookinfo/
# Usage:
#   chmod +x bookinfo.sh
#   ./bookinfo.sh
################################################################################
shopt -o -s errexit   #—Terminates  the shell script if a command returns an error code.
#shopt -o -s xtrace    #—Displays each command before it is executed.
shopt -o -s nounset   #-No Variables without definition
set -euo pipefail

kubectl label namespace demo-istio istio-injection=enabled
kubectl apply --namespace demo-istio -f https://raw.githubusercontent.com/istio/istio/release-1.28/samples/bookinfo/platform/kube/bookinfo.yaml
kubectl apply --namespace demo-istio -f https://raw.githubusercontent.com/istio/istio/release-1.28/samples/bookinfo/platform/kube/bookinfo-versions.yaml
kubectl apply --namespace demo-istio -f https://raw.githubusercontent.com/istio/istio/release-1.28/samples/bookinfo/gateway-api/bookinfo-gateway.yaml
