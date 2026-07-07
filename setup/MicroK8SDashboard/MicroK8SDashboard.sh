#!/bin/bash
############################################################################################
#
# ${KUBECTL} enable Dashboard     # https://microk8s.io/docs/addon-dashboard
# ${KUBECTL} enable Dashboard-Ingress # https://microk8s.io/docs/addon-dashboard-ingress
#
############################################################################################
set -euo pipefail

indir="$(dirname "$0")"

KUBECTL="sudo microk8s.kubectl"
HELM="${KUBECTL} helm"
target_dir="."
  
echo "Checking if ${KUBECTL} is installed..."
if ! command -v ${KUBECTL} &> /dev/null; then
  echo "Error: ${KUBECTL} is not installed. Please install ${KUBECTL} first."
  exit 1
fi

# delete all YAML files in the target directory
echo "Deleting YAML files in $target_dir ..."
mapfile -t yamls < <(find "$target_dir" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort)
if [ "${#yamls[@]}" -eq 0 ]; then
  echo "No YAML files found in $target_dir"
else
  for f in "${yamls[@]}"; do
    echo "Applying $f"
    envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < ${f} | ${KUBECTL} delete -f  - || true 
  done
fi

${KUBECTL} status --wait-ready

echo "Disabling dashboard and dashboard-ingress if enabled..."
${KUBECTL} disable dashboard-ingress || true
${KUBECTL} status --wait-ready
${KUBECTL} disable dashboard || true
${KUBECTL} status --wait-ready

echo "Enabling dashboard and dashboard-ingress..."
${KUBECTL} enable dashboard
${KUBECTL} enable dashboard-ingress
${KUBECTL} status --wait-ready

# Apply all YAML files in the target directory
echo "Applying YAML files in $target_dir ..."
mapfile -t yamls < <(find "$target_dir" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort)
if [ "${#yamls[@]}" -eq 0 ]; then
  echo "No YAML files found in $target_dir"
else
  for f in "${yamls[@]}"; do
    echo "Applying $f"
    envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < ${f} | ${KUBECTL} apply -f  - || true 
  done
fi

${KUBECTL} status --wait-ready

echo "Creating long-lived cluster-admin token (${KUBECTL} 1.24+)..."
token=$(${KUBECTL} kubectl create token cluster-admin -n kubernetes-dashboard --duration=8760h || true)

echo "Modify ./kube/config ..."
sudo sed -i '/token:/d' ~/.kube/config
sudo sed -i -e '$a\'$'\n'"    token: ${token}" ~/.kube/config
echo "Kubeconfig updated with dashboard token."
cat ~/.kube/config

# Using Istio

# Modify Type to loadBalancer
echo "Modifying kubernetes-dashboard service type to LoadBalancer..."
${KUBECTL} kubectl patch service kubernetes-dashboard-kong-proxy -n kubernetes-dashboard --type='json' -p='[{"op": "replace", "path": "/spec/type", "value": "LoadBalancer"}]'  || true
echo "Waiting for the dashboard Deployment to be ready..."
${KUBECTL} kubectl wait --for=condition=available --timeout=60s deployment/kubernetes-dashboard-kong -n kubernetes-dashboard
echo "Waiting for the dashboard pod to be ready..."
${KUBECTL} kubectl wait --for=condition=ready --timeout=60s pod -l app.kubernetes.io/name=kong -n kubernetes-dashboard

echo "Done. Dashboard should be available via Ingress."
${KUBECTL} kubectl get ingress -n kubernetes-dashboard kubernetes-dashboard-ingress -o wide

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
# kubectl -n kube-system describe secret $(${KUBECTL} kubectl -n kube-system get secret | grep default-token | cut -d " " -f1)
# kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print \$1}')
#
# Jetzt sind alle Standard-Services verfügbar
#
# kubernetes-dashboard.${K8S_ENVIRONMENT}.slainte.at in die /etc/hosts Datei eintragen, und man kann über den Ingress auf das Dashboard zugreifen
#