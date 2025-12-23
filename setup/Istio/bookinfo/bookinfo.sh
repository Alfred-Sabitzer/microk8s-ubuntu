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

export NAMESPACE="bookinfo"
export istio_dir="/opt/istio-installation/istio-1.28.1"

# Create namespace for Bookinfo application
kubectl create namespace ${NAMESPACE} || true
# Enable Istio sidecar injection for the namespace
kubectl label namespace ${NAMESPACE} istio.io/dataplane-mode=ambient --overwrite || warn "Failed to label demo-istio"

# Clean up any previous Bookinfo installation
echo "Cleaning up any previous Bookinfo installation in namespace '${NAMESPACE}'..."

chmod +x ${istio_dir}/samples/bookinfo/platform/kube/cleanup.sh
${istio_dir}/samples/bookinfo/platform/kube/cleanup.sh || true

# Install Gateway API CRDs if not already present
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
{ kubectl apply --server-side -f https://github.comkubectl get gtw bookinfo-gateway/kubernetes-sigs/gateway-api/releases/download/v1.4.1/standard-install.yaml ; }

# Deploy Bookinfo application
kubectl apply --namespace ${NAMESPACE} -f ${istio_dir}/samples/bookinfo/platform/kube/bookinfo.yaml
kubectl apply --namespace ${NAMESPACE} -f ${istio_dir}/samples/bookinfo/platform/kube/bookinfo-versions.yaml
kubectl apply --namespace ${NAMESPACE} -f ${istio_dir}/samples/bookinfo/gateway-api/bookinfo-gateway.yaml 

# Wait for Gateway to be programmed
echo "Waiting for Bookinfo Gateway to be programmed..."
sleep 5
kubectl wait --for=condition=programmed gtw bookinfo-gateway -n ${NAMESPACE}
# Get Ingress Gateway details for accessing the application
echo "Get Ingress Gateway details for accessing the application"
export INGRESS_HOST=$(kubectl get gtw bookinfo-gateway -n ${NAMESPACE} -o jsonpath='{.status.addresses[0].value}')
export INGRESS_PORT=$(kubectl get gtw bookinfo-gateway -n ${NAMESPACE} -o jsonpath='{.spec.listeners[?(@.name=="http")].port}')
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
echo "Bookinfo Gateway URL: http://$GATEWAY_URL"

# Wait for pods to be ready
echo "Waiting for Bookinfo pods to become Ready in namespace '${NAMESPACE}'..."
if ! kubectl wait --for=condition=Ready pod -n ${NAMESPACE} --all --timeout=120s 2>/dev/null; then
  echo "Warning: some Bookinfo pods did not report Ready within 120s; inspect with 'kubectl -n ${NAMESPACE} get pods -o wide'"
fi

echo "Listing Bookinfo pods:"
kubectl -n ${NAMESPACE} get pods -o wide || true
echo "Listing Bookinfo services:"
kubectl -n ${NAMESPACE} get svc -o wide || true
echo "Bookinfo application deployed in namespace '${NAMESPACE}'."
echo "You can access the application via the Istio Ingress Gateway."
echo "For example, if your environment is accessible at http://${K8S_ENVIRONMENT}.bookinfo.slainte.at, you can access the Bookinfo application at:"
echo "http://${K8S_ENVIRONMENT}.bookinfo.slainte.at/productpage"
echo ""