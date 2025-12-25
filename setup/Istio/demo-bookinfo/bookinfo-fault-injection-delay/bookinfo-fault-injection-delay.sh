#!/bin/bash
################################################################################
#
# Install Bookinfo sample fault injection
# See https://istio.io/latest/docs/tasks/traffic-management/fault-injection/
################################################################################
shopt -o -s errexit   #—Terminates  the shell script if a command returns an error code.
#shopt -o -s xtrace    #—Displays each command before it is executed.
shopt -o -s nounset   #-No Variables without definition
set -euo pipefail

export NAMESPACE="bookinfo"
export istio_dir="/opt/istio-installation/istio-1.28.1"

# Deploy Bookinfo fault injection - this is with the standard Istio API
echo "Deploying Bookinfo fault injection in namespace '${NAMESPACE}'..."
kubectl apply --namespace ${NAMESPACE} -f ${istio_dir}/samples/bookinfo/networking/virtual-service-all-v1.yaml
kubectl apply --namespace ${NAMESPACE} -f ${istio_dir}/samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml
kubectl apply --namespace ${NAMESPACE} -f ${istio_dir}/samples/bookinfo/networking/virtual-service-ratings-test-delay.yaml

# Wait for pods to be ready
echo "Waiting for Bookinfo pods to become Ready in namespace '${NAMESPACE}'..."
if ! kubectl wait --for=condition=Ready pod -n ${NAMESPACE} --all --timeout=120s 2>/dev/null; then
  echo "Warning: some Bookinfo pods did not report Ready within 120s; inspect with 'kubectl -n ${NAMESPACE} get pods -o wide'"
fi

exit 0