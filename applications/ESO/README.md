# External Secret Operator

https://www.kubermatic.com/learn/security/syncing-secrets-external-secrets-operator/

To sync secrets from [OpenBao](https://openbao.org/) (the open-source fork of HashiCorp Vault) into native Kubernetes Secrets, the most robust and cloud-native method is using the External Secrets Operator (ESO). [1] 
Alternatively, you can use the community's own OpenBao Secrets Operator (BSO), which mirrors the functionality of HashiCorp's Vault Secrets Operator. The guide below utilizes ESO due to its widespread multi-backend adoption and flexibility.

------------------------------
## Step 1: Install External Secrets Operator (ESO)
Add the Helm repository and install the operator into your cluster:

helm repo add external-secrets https://external-secrets.io
helm install external-secrets external-secrets/external-secrets -n external-secrets --create-namespace

## Step 2: Configure Kubernetes Auth Method in OpenBao
OpenBao needs to trust your Kubernetes cluster so the operator can authenticate. Run the following inside your OpenBao environment:

````bash
# Enable Kubernetes authentication
bao auth enable kubernetes
# Configure the connection to the local cluster API
bao write auth/kubernetes/config \
    kubernetes_host="https://cluster.local"
# Create a role linking the ESO ServiceAccount to an OpenBao read policy
bao write auth/kubernetes/role/eso-role \
    bound_service_account_names=external-secrets \
    bound_service_account_namespaces=external-secrets \
    policies=myapp-read-policy \
    ttl=1h
````

(Note: Ensure myapp-read-policy grants explicit read capabilities to your desired KV engine path).
## Step 3: Create a SecretStore in Kubernetes
The SecretStore resource teaches ESO how to connect and log into OpenBao. Apply the following manifest (secretstore.yaml):

````yaml
apiVersion: external-secrets.io/v1beta1kind: SecretStoremetadata:
  name: openbao-backend
  namespace: my-app-namespacespec:
  provider:
    vault: # ESO leverages the Vault-compatible API endpoints of OpenBao
      server: "http://cluster.local"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "eso-role"
          serviceAccountRef:
            name: "external-secrets"
            namespace: "external-secrets"
````

Apply it: kubectl apply -f secretstore.yaml

## Step 4: Define the ExternalSecret (The Sync Mechanism)
The ExternalSecret tells ESO exactly what keys to pull from OpenBao and how to map them into a native Kubernetes Secret. Apply this manifest (externalsecret.yaml):

````yaml
apiVersion: external-secrets.io/v1beta1kind: ExternalSecretmetadata:
  name: myapp-external-secret
  namespace: my-app-namespacespec:
  refreshInterval: "1m" # How often ESO polls OpenBao for changes
  secretStoreRef:
    name: openbao-backend
    kind: SecretStore
  target:
    name: myapp-native-secret # The name of the native K8s Secret to create
    creationPolicy: Owner
  data:
    - secretKey: DB_PASSWORD       # Key inside the Kubernetes Secret
      remoteRef:
        key: myapp/config          # Path inside OpenBao KV engine
        property: db_password      # Specific key field within that OpenBao secret
````

Apply it: kubectl apply -f externalsecret.yaml
------------------------------
## Verification & Drift Sync

* Verify Sync Status: Run kubectl get externalsecret -n my-app-namespace. The status should read SecretSynced.
* Verify Native Secret: Run kubectl get secret myapp-native-secret -n my-app-namespace -o yaml to see your base64-encoded secret data natively inside etcd.
* Automatic Updates: If you update the secret value in OpenBao (e.g., bao kv put secret/myapp/config db_password=newpassword), ESO will automatically update the native Kubernetes secret within the 1-minute refreshInterval window.

[1] [https://liquidreply.net](https://liquidreply.net/news/openbao-securing-the-future-of-open-source-secrets-management)

See as well https://www.kubermatic.com/learn/security/syncing-secrets-external-secrets-operator/
