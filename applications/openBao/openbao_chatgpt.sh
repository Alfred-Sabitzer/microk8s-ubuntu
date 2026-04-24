🎯 🧱 Required Helm Charts
1️⃣ OpenBao (core secret engine)

👉 This is the main system

You deploy OpenBao itself via a Helm chart:

Provides:
API server
storage backend
auth methods
secret engines
Helm repo

Most setups use a Vault-compatible chart:

helm repo add hashicorp https://helm.releases.hashicorp.com

Then:

helm install openbao hashicorp/vault \
  -n openbao --create-namespace

👉 Even though it's named “vault”, it works with OpenBao.

🔐 2️⃣ Secrets Store CSI Driver

👉 Required to mount secrets into pods

helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts

helm install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver \
  -n kube-system

🔌 3️⃣ OpenBao / Vault Provider for CSI

👉 This is the bridge between CSI and OpenBao

helm repo add hashicorp https://helm.releases.hashicorp.com

helm install csi-provider hashicorp/vault \
  -n kube-system \
  --set "csi.enabled=true"

✔️ Provides:

secrets-store.csi.k8s.io integration
authentication to OpenBao
secret retrieval


🔄 4️⃣ (Optional) Secret Sync Controller

👉 Only needed if you want:

secretObjects:

Then Kubernetes Secrets are created automatically.

❗ Important: You must enable it explicitly
helm install csi-provider hashicorp/vault \
  -n kube-system \
  --set "csi.enabled=true" \
  --set "csi.secretSync.enabled=true"


  ####

  apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: csi-secret-sync
  namespace: openbaotest
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["create", "update", "patch"]


  apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: csi-secret-sync-binding
  namespace: openbaotest
subjects:
- kind: ServiceAccount
  name: secrets-store-csi-driver   # 👈 THIS is the key
  namespace: kube-system
roleRef:
  kind: Role
  name: csi-secret-sync
  apiGroup: rbac.authorization.k8s.io


 kind: ClusterRoleBinding
roleRef:
  name: system:auth-delegator
subjects:
- kind: ServiceAccount
  name: openbao
  namespace: openbao 