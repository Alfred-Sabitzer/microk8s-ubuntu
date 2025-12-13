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

export NAMESPACE="demo-istio"


# Clean up any previous Bookinfo installation
echo "Cleaning up any previous Bookinfo installation in namespace '${NAMESPACE}'..."

wget https://raw.githubusercontent.com/istio/istio/release-1.28/samples/bookinfo/platform/kube/cleanup.sh
chmod +x cleanup.sh
./cleanup.sh || true
rm -f cleanup.sh
echo "Previous Bookinfo installation cleaned up."

# Create namespace for Bookinfo application
kubectl create namespace ${NAMESPACE} || true
# Enable Istio sidecar injection for the namespace
kubectl label namespace ${NAMESPACE} istio-injection=enabled

# Install Gateway API CRDs if not already present
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
{ kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.1/standard-install.yaml ; }

rm -f bookinfo.yaml destination-rule-all.yaml bookinfo-gateway.yaml
# get Bookinfo application YAML files
wget https://raw.githubusercontent.com/istio/istio/refs/heads/release-1.18.2-patch/samples/bookinfo/platform/kube/bookinfo.yaml
wget https://raw.githubusercontent.com/istio/istio/refs/heads/release-1.18.2-patch/samples/bookinfo/networking/destination-rule-all.yaml
wget https://raw.githubusercontent.com/istio/istio/refs/heads/release-1.18.2-patch/samples/bookinfo/networking/bookinfo-gateway.yaml


# Deploy Bookinfo application
kubectl apply --namespace ${NAMESPACE} -f ./bookinfo.yaml
kubectl apply --namespace ${NAMESPACE} -f ./destination-rule-all.yaml
kubectl apply --namespace ${NAMESPACE} -f ./bookinfo-gateway.yaml

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

