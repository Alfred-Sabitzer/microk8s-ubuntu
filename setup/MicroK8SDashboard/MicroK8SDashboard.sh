#!/bin/bash
############################################################################################
#
# MicroK8S enable Dashboard     # https://microk8s.io/docs/addon-dashboard
# MicroK8S enable Dashboard-Ingress # https://microk8s.io/docs/addon-dashboard-ingress
#
############################################################################################
set -euo pipefail

indir="$(dirname "$0")"

echo "Checking if microk8s is installed..."
if ! command -v microk8s &> /dev/null; then
  echo "Error: microk8s is not installed. Please install microk8s first."
  exit 1
fi

echo "Disabling dashboard and dashboard-ingress if enabled..."
microk8s disable dashboard-ingress || true
microk8s disable dashboard || true

if [ -f "${indir}/dashboard-service-account.yaml" ]; then
  microk8s kubectl delete -f "${indir}/dashboard-service-account.yaml" --ignore-not-found
else
  echo "Warning: dashboard-service-account.yaml not found."
fi

microk8s status --wait-ready

echo "Enabling dashboard and dashboard-ingress..."
microk8s enable dashboard
microk8s enable dashboard-ingress

if [ -f "${indir}/dashboard-service-account.yaml" ]; then
  microk8s kubectl apply -f "${indir}/dashboard-service-account.yaml"
else
  echo "Warning: dashboard-service-account.yaml not found."
fi

microk8s status --wait-ready

echo "Creating long-lived cluster-admin token (MicroK8s 1.24+)..."
microk8s kubectl create token cluster-admin -n kube-system --duration=8760h || true

echo "Done. Dashboard should be available via Ingress."
#
# Dieses Token gehört dann in die .kube/config
#
# users:
# - name: admin
#   user:
#    client-certificate-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUN6RENDQWJTZ0F3SUJBZ0lVWEFSb0hJaGZrU1VaSythQ0k1eWY2MD>
#    client-key-data: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFcFFJQkFBS0NBUUVBdFBjdHV1QWkvbTdxVHlvWGZHd2VmQjYxWm5raW>
#    token: eyJhbGciOiJSUzI1NiIsImtpZCI6IjJKNVF6Z25hTVBJWFF3UWQ0QnJSVHVKVEVSbmZVVG9FWDluSFhuWjZYcXMifQ.eyJhdWQiOlsiaHR0cHM6L>
#
#
# Anzeigen der Tokens
# kubectl -n kube-system get secrets microk8s-dashboard-token -o go-template="{{.data.token | base64decode}}"
# kubectl -n kube-system get secret $(kubectl -n kube-system get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}"
# kubectl -n kube-system describe secret $(microk8s kubectl -n kube-system get secret | grep default-token | cut -d " " -f1)
# kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print \$1}')
#
# Jetzt sind alle Standard-Services verfügbar
#
# kubernetes-dashboard.127.0.0.1.nip.io in die /etc/hosts Datei eintragen, und man kann über den Ingress auf das Dashboard zugreifen
#