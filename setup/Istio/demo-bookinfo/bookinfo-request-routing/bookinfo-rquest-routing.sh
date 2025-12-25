#!/bin/bash
################################################################################
#
# Install Bookinfo sample request routing
# See https://istio.io/latest/docs/tasks/traffic-management/request-routing/ 
################################################################################
shopt -o -s errexit   #—Terminates  the shell script if a command returns an error code.
#shopt -o -s xtrace    #—Displays each command before it is executed.
shopt -o -s nounset   #-No Variables without definition
set -euo pipefail

export NAMESPACE="bookinfo"
export istio_dir="/opt/istio-installation/istio-1.28.1"

# Deploy Bookinfo request routing - this is with the standard Istio API
echo "Deploying Bookinfo request routing in namespace '${NAMESPACE}'..."
kubectl apply -f --namespace ${NAMESPACE} -f ${istio_dir}/samples/bookinfo/networking/virtual-service-all-v1.yaml
kubectl apply -f --namespace ${NAMESPACE} -f ${istio_dir}/samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml

# Wait for pods to be ready
echo "Waiting for Bookinfo pods to become Ready in namespace '${NAMESPACE}'..."
if ! kubectl wait --for=condition=Ready pod -n ${NAMESPACE} --all --timeout=120s 2>/dev/null; then
  echo "Warning: some Bookinfo pods did not report Ready within 120s; inspect with 'kubectl -n ${NAMESPACE} get pods -o wide'"
fi

echo "Current Bookinfo VirtualServices and DestinationRules:"  
kubectl get virtualservices -n ${NAMESPACE} -o yaml
kubectl get destinationrules -n ${NAMESPACE} -o yaml

exit 0