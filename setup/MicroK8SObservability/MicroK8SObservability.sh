#!/bin/bash
############################################################################################
#
# MicroK8S enable observability    # https://microk8s.io/docs/addons
# 
# Prometheus is deprecated in favor of observability-operator
#
# https://collabnix.com/installing-prometheus-on-microk8s-in-2025-a-step-by-step-guide/
#
############################################################################################
set -euo pipefail

indir="$(dirname "$0")"

echo "Checking if microk8s is installed..."
if ! command -v microk8s &> /dev/null; then
  echo "Error: microk8s is not installed. Please install microk8s first."
  exit 1
fi

microk8s kubectl delete -f "${indir}/kube_promstack_kube_prome_prometheus_ingress.yaml" || true
microk8s kubectl delete -f "${indir}/kube_prom_stack_grafana.yaml" || true

echo "Disabling Observability if enabled..."
microk8s disable observability|| true
microk8s status --wait-ready

echo "Enabling observability ..."
microk8s enable observability || true                # (core) A lightweight observability stack for logs, traces and metrics
microk8s status --wait-ready

# Modify Type to loadBalancer
echo "Modifying kube-prom-stack-kube-prome-prometheus service type to LoadBalancer..."  
microk8s kubectl patch service kube-prom-stack-kube-prome-prometheus -n observability --type='json' -p='[{"op": "replace", "path": "/spec/type", "value": "LoadBalancer"}]'  || true

# Modify Prometheus configuration
echo "Modifying Prometheus configuration..."
kubectl get secret -n observability prometheus-kube-prom-stack-kube-prome-prometheus -o 'go-template={{index .data "prometheus.yaml.gz"}}' | base64 -d | gzip -d > /tmp/prometheus.yaml
# Modify the prometheus.yaml file as needed
sed -i 's/insecure_skip_verify: false/insecure_skip_verify: true/g' /tmp/prometheus.yaml
cat /tmp/prometheus.yaml | grep "insecure_skip_verify: true" || true

# For example, you can add or modify scrape configs here
cat << EOF | microk8s kubectl replace -f -
apiVersion: v1
data:
  prometheus.yaml.gz: $(cat /tmp/prometheus.yaml | gzip | base64 | tr -d '\n')
kind: Secret
metadata:
  annotations:
    generated: "true"
  labels:
    managed-by: prometheus-operator
  name: prometheus-kube-prom-stack-kube-prome-prometheus
  namespace: observability
  ownerReferences:
  - apiVersion: monitoring.coreos.com/v1
    blockOwnerDeletion: true
    controller: true
    kind: Prometheus
    name: kube-prom-stack-kube-prome-prometheus
    uid: f96b015a-ca7d-422d-a733-2dfad50f8b68
type: Opaque
EOF

# Clean up the temporary prometheus.yaml file
rm -f /tmp/prometheus.yaml
# Wait for Prometheus to be ready
echo "Waiting for the kube-prom-stack-kube-prome-operator pod to be ready..."
microk8s kubectl wait --for=condition=ready --timeout=60s pod -l app=kube-prometheus-stack-operator -n observability

# Own ingress for local access to prometheus
echo "Applying kube_promstack_kube_prome_prometheus_ingress.yaml ..."
if [ -f "${indir}/kube_promstack_kube_prome_prometheus_ingress.yaml" ]; then
  microk8s kubectl apply -f "${indir}/kube_promstack_kube_prome_prometheus_ingress.yaml"
else
  echo "Warning: kube_promstack_kube_prome_prometheus_ingress.yaml not found."
fi

# Modify Grafana Service Type to loadBalancer
echo "Modifying kube-prom-stack-grafana service type to LoadBalancer..."  
microk8s kubectl patch service kube-prom-stack-grafana -n observability --type='json' -p='[{"op": "replace", "path": "/spec/type", "value": "LoadBalancer"}]'  || true
echo "Waiting for the kube-prom-stack-grafana deployment to be ready..."
microk8s kubectl wait --for=condition=available --timeout=60s deployment/kube-prom-stack-grafana -n observability || true
echo "Waiting for the kube-prom-stack-grafana pod to be ready..."
microk8s kubectl wait --for=condition=ready --timeout=60s pod -l app.kubernetes.io/name=grafana -n observability || true
echo "Done. Dashboard should be available via Ingress."

# Own ingress for local access to the dashboard
echo "Applying kube_prom_stack_grafana.yaml ..."
if [ -f "${indir}/kube_prom_stack_grafana.yaml" ]; then
  microk8s kubectl apply -f "${indir}/kube_prom_stack_grafana.yaml"
else
  echo "Warning: kube_prom_stack_grafana.yaml not found."
fi

microk8s kubectl get ingress -n observability  -o wide
echo "Prometheus service is available at:"
microk8s kubectl get svc -n observability kube-prom-stack-kube-prome-prometheus -o yaml | grep -i " ip:" || true
echo "Grafana service is available at:"
microk8s kubectl get svc -n observability kube-prom-stack-grafana -o yaml | grep -i " ip:" || true

exit

# Test on your local machine:
# Check if the observability namespace exists
if microk8s kubectl get namespace observability &> /dev/null; then
  echo "Observability namespace exists."
else
  echo "Creating observability namespace..."
  microk8s kubectl create namespace observability
fi


# Observability has been enabled (user/pass: admin/prom-operator)
# https://collabnix.com/installing-prometheus-on-microk8s-in-2025-a-step-by-step-guide/
kubectl get pods -n observability -l "app.kubernetes.io/instance=kube-prom-stack-kube-prome-prometheus" -o jsonpath="{.items[0].metadata.name}"
# Visit http://localhost:9090 in your browser to access the Prometheus interface.

# If you want to access Prometheus via port-forwarding, you can use the following command:
# Port-forwarding to access Prometheus
kubectl port-forward -n observability pod/prometheus-kube-prom-stack-kube-prome-prometheus-0 7777:9090
# or use the service directly
kubectl port-forward -n observability service/kube-prom-stack-kube-prome-prometheus 7777:9090
