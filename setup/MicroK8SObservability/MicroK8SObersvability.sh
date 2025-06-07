#!/bin/bash
############################################################################################
#
# MicroK8S enable observability    # https://microk8s.io/docs/addons
# 
# Prometheus is deprecated in favor of observability-operator
#
############################################################################################
set -euo pipefail

indir="$(dirname "$0")"

echo "Checking if microk8s is installed..."
if ! command -v microk8s &> /dev/null; then
  echo "Error: microk8s is not installed. Please install microk8s first."
  exit 1
fi

microk8s kubectl delete -f "${indir}/kube_prom_stack_kube_prome_operator_ingress.yaml" || true
microk8s kubectl delete -f "${indir}/kube_prom_stack_grafana.yaml" || true

echo "Disabling Observability if enabled..."
microk8s disable observability|| true

microk8s status --wait-ready

echo "Enabling observability ..."
microk8s enable observability || true                # (core) A lightweight observability stack for logs, traces and metrics
microk8s status --wait-ready

# Own ingress for local access to the dashboard
echo "Applying kube_prom_stack_kube_prome_operator_ingress.yaml ..."
if [ -f "${indir}/kube_prom_stack_kube_prome_operator_ingress.yaml" ]; then
  microk8s kubectl apply -f "${indir}/kube_prom_stack_kube_prome_operator_ingress.yaml"
else
  echo "Warning: kube_prom_stack_kube_prome_operator_ingress.yaml not found."
fi

# Modify Type to loadBalancer
echo "Modifying kube-prom-stack-kube-prome-operator service type to LoadBalancer..."  
microk8s kubectl patch service kube-prom-stack-kube-prome-operator -n observability --type='json' -p='[{"op": "replace", "path": "/spec/type", "value": "LoadBalancer"}]'  || true
echo "Waiting for the kube-prom-stack-kube-prome-operator deployment to be ready..."
microk8s kubectl wait --for=condition=available --timeout=60s deployment/kube-prom-stack-kube-prome-operator -n observability
echo "Waiting for the kube-prom-stack-kube-prome-operator pod to be ready..."
microk8s kubectl wait --for=condition=ready --timeout=60s pod -l app=kube-prometheus-stack-operator -n observability


# Own ingress for local access to the dashboard
echo "Applying kube_prom_stack_grafana.yaml ..."
if [ -f "${indir}/kube_prom_stack_grafana.yaml" ]; then
  microk8s kubectl apply -f "${indir}/kube_prom_stack_grafana.yaml"
else
  echo "Warning: kube_prom_stack_grafana.yaml not found."
fi

# Modify Type to loadBalancer
echo "Modifying kube-prom-stack-grafana service type to LoadBalancer..."  
microk8s kubectl patch service kube-prom-stack-grafana -n observability --type='json' -p='[{"op": "replace", "path": "/spec/type", "value": "LoadBalancer"}]'  || true
echo "Waiting for the kube-prom-stack-grafana deployment to be ready..."
microk8s kubectl wait --for=condition=available --timeout=60s deployment/kube-prom-stack-grafana -n observability
echo "Waiting for the kube-prom-stack-grafana pod to be ready..."
microk8s kubectl wait --for=condition=ready --timeout=60s pod -l app.kubernetes.io/name=grafana -n observability

echo "Done. Dashboard should be available via Ingress."
microk8s kubectl get ingress -n observability  -o wide

# Observability has been enabled (user/pass: admin/prom-operator)
