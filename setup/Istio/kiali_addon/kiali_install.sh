#!/bin/bash
################################################################################
#
# Install Kiali on MicroK8s, optionally deploy a demo app.
#
################################################################################
set -euo pipefail

kubectl apply -f ./kiali.yaml

# # detect required commands
# HELM="${HELM:-microk8s helm3}"
# KUBECTL="${KUBECTL:-microk8s kubectl}"
# NAMESPACE="${NAMESPACE:-istio-system}"

# ${HELM} repo add kiali https://kiali.org/helm-charts
# ${HELM} repo update

# ${HELM} uninstall -n ${NAMESPACE} kiali-operator || true

# ${HELM} install -n ${NAMESPACE} --create-namespace \
#   -f values-kiali.yaml \
#   kiali-operator kiali/kiali-operator

# ${HELM} list --all-namespaces
