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

# Install Gateway API CRDs if not already present
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
{ kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.1/standard-install.yaml ; }

# Deploy Bookinfo application
kubectl apply --namespace demo-istio -f https://raw.githubusercontent.com/istio/istio/release-1.28/samples/bookinfo/platform/kube/bookinfo.yaml
kubectl apply --namespace demo-istio -f https://raw.githubusercontent.com/istio/istio/release-1.28/samples/bookinfo/platform/kube/bookinfo-versions.yaml
kubectl apply --namespace demo-istio -f https://raw.githubusercontent.com/istio/istio/release-1.28/samples/bookinfo/gateway-api/bookinfo-gateway.yaml
#
# Wait for pods to be ready
echo "Waiting for Bookinfo pods to become Ready in namespace 'demo-istio'..."
if ! kubectl wait --for=condition=Ready pod -n demo-istio --all --timeout=120s 2>/dev/null; then
  echo "Warning: some Bookinfo pods did not report Ready within 120s; inspect with 'kubectl -n demo-istio get pods -o wide'"
fi
echo "Listing Bookinfo pods:"
kubectl -n demo-istio get pods -o wide || true  
echo "Listing Bookinfo services:"
kubectl -n demo-istio get svc -o wide || true
echo "Bookinfo application deployed in namespace 'demo-istio'."
echo "You can access the application via the Istio Ingress Gateway." 
echo "For example, if your environment is accessible at http://${K8S_ENVIRONMENT}.http.slainte.at, you can access the Bookinfo application at:"
echo "http://${K8S_ENVIRONMENT}.http.slainte.at/productpage"
echo ""

