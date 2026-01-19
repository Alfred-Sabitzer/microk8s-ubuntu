#!/bin/bash
############################################################################################
#
# sudo microk8s enable Dashboard     # https://microk8s.io/docs/addon-dashboard
# sudo microk8s enable Dashboard-Ingress # https://microk8s.io/docs/addon-dashboard-ingress
#
############################################################################################
set -euo pipefail

indir="$(dirname "$0")"

echo "Checking if sudo microk8s is installed..."
if ! command -v sudo microk8s &> /dev/null; then
  echo "Error: sudo microk8s is not installed. Please install sudo microk8s first."
  exit 1
fi

if [ -f "${indir}/dashboard-service-account.yaml" ]; then
  sudo microk8s kubectl delete -f "${indir}/dashboard-service-account.yaml" --ignore-not-found
else
  echo "Warning: dashboard-service-account.yaml not found."
fi
sudo microk8s status --wait-ready

echo "Disabling dashboard and dashboard-ingress if enabled..."
sudo microk8s disable dashboard-ingress || true
sudo microk8s status --wait-ready
sudo microk8s disable dashboard || true
sudo microk8s status --wait-ready

echo "Enabling dashboard and dashboard-ingress..."
sudo microk8s enable dashboard
sudo microk8s enable dashboard-ingress

# configure the dashboard service account with cluster-admin permissions
echo "Applying dashboard-service-account.yaml..."
if [ -f "${indir}/dashboard-service-account.yaml" ]; then
  sudo microk8s kubectl apply -f "${indir}/dashboard-service-account.yaml"
else
  echo "Warning: dashboard-service-account.yaml not found."
fi

# Own ingress for local access to the dashboard
echo "Applying kubernetes-dashboard-ingress.yaml..."
if [ -f "${indir}/kubernetes-dashboard-#deployment.apps/rook-ceph-operator                         1/1     1            1           6m44s
#deployment.apps/rook-ceph.cephfs.csi.ceph.com-ctrlplugin   1/1     1            1           3m46s
#deployment.apps/rook-ceph.rbd.csi.ceph.com-ctrlplugin      1/1     1            1           3m46s
#
#NAME                                                                 DESIRED   CURRENT   READY   AGE
#replicaset.apps/ceph-csi-controller-manager-78d4fd465                1         1         1       6m44s
#replicaset.apps/rook-ceph-operator-7fc848bf99                        1         1         1       6m44s
#replicaset.apps/rook-ceph.cephfs.csi.ceph.com-ctrlplugin-5456dbbd6   1         1         1       3m46s
#replicaset.apps/rook-ceph.rbd.csi.ceph.com-ctrlplugin-58d6cb98cb     1         1         1       3m46s
#ansible@k8stest:~/ceph/rook/deploy/charts/rook-ceph-cluster$

````

Then proceed with your tests.


## Security notes
- Do not commit `ceph.conf` or keyrings to version control.
- Keep access to Ceph keyrings and admin credentials restricted.
- For production, prefer secure secret management rather than plaintext files.
ingress.yaml" ]; then
  envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < "${indir}/kubernetes-dashboard-ingress.yaml" | sudo microk8s kubectl apply -f -
else
  echo "Warning: kubernetes-dashboard-ingress.yaml not found."
fi

sudo microk8s status --wait-ready

echo "Creating long-lived cluster-admin token (sudo microk8s 1.24+)..."
token=$(sudo microk8s kubectl create token cluster-admin -n kubernetes-dashboard --duration=8760h || true)

echo "Modify ./kube/config ..."
sudo sed -i '/token:/d' ~/.kube/config
sudo sed -i -e '$a\'$'\n'"    token: ${token}" ~/.kube/config
echo "Kubeconfig updated with dashboard token."
cat ~/.kube/config

# Modify Type to loadBalancer
echo "Modifying kubernetes-dashboard service type to LoadBalancer..."
sudo microk8s kubectl patch service kubernetes-dashboard-kong-proxy -n kubernetes-dashboard --type='json' -p='[{"op": "replace", "path": "/spec/type", "value": "LoadBalancer"}]'  || true
echo "Waiting for the dashboard Deployment to be ready..."
sudo microk8s kubectl wait --for=condition=available --timeout=60s deployment/kubernetes-dashboard-kong -n kubernetes-dashboard
echo "Waiting for the dashboard pod to be ready..."
sudo microk8s kubectl wait --for=condition=ready --timeout=60s pod -l app.kubernetes.io/name=kong -n kubernetes-dashboard

echo "Done. Dashboard should be available via Ingress."
sudo microk8s kubectl get ingress -n kubernetes-dashboard kubernetes-dashboard-ingress -o wide

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
# kubectl -n kube-system describe secret $(sudo microk8s kubectl -n kube-system get secret | grep default-token | cut -d " " -f1)
# kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print \$1}')
#
# Jetzt sind alle Standard-Services verfügbar
#
# kubernetes-dashboard.127.0.0.1.nip.io in die /etc/hosts Datei eintragen, und man kann über den Ingress auf das Dashboard zugreifen
#