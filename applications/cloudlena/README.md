# Cloudlena - S3 browser

Cloudlena is a lightweight browser for S3-compatible object storage. The manifests in this directory deploy the Cloudlena UI together with the required service account, RBAC rules, and a CSI-based secret provider for OpenBao.

## What is deployed

The deployment includes:
- a dedicated namespace for the application
- a service account and RBAC rules for the pod
- a SecretProviderClass that reads credentials from OpenBao through the CSI driver
- a Deployment for the Cloudlena container
- a Service and Istio VirtualService for ingress
- a HorizontalPodAutoscaler for basic scaling

## Prerequisites

- MicroK8s with the Kubernetes API available
- kubectl access to the target cluster
- the secrets-store CSI driver and OpenBao integration already available in the cluster
- envsubst installed on the machine running the script

## Configuration

The helper script renders the YAML files with environment variables. The most important variables are:

- NAMESPACE: target namespace for the deployment (default: cloudlena)
- K8S_ENVIRONMENT: suffix used in the generated ingress hostname (default: dev)
- OPENBAO_ADDRESS: address of the OpenBao service (default: http://openbao.openbao.svc:8200)
- OPENBAO_SECRET_PATH: secret path used by the SecretProviderClass (default: secret/data/cloudlena/cloudlena)
- OPENBAO_ROLE: OpenBao role used by the CSI provider (default: cloudlena-role)
- RETRY_ATTEMPTS / RETRY_DELAY: retry policy for apply and delete operations
- MICROK8S_CMD: optional override for the MicroK8s CLI prefix, for example sudo microk8s

## Usage

Run the helper script from this directory:

```bash
./cloudlena.sh
```

Show the usage text:

```bash
./cloudlena.sh --help
```

Example with custom values:

```bash
NAMESPACE=cloudlena \
K8S_ENVIRONMENT=prod \
OPENBAO_ADDRESS=http://openbao.openbao.svc:8200 \
OPENBAO_SECRET_PATH=secret/data/cloudlena/cloudlena \
./cloudlena.sh
```

## Notes

- The script deletes existing resources from the YAML files first and then re-applies them, which makes it suitable for refresh operations.
- The Deployment uses a read-only root filesystem and a writable tmp volume to keep the container more resilient while still allowing temporary files.
- The ingress hostname is templated as cloudlena.${K8S_ENVIRONMENT}.slainte.at and should match an existing Istio gateway route.

## Validation

After deployment, verify the rollout with:

```bash
microk8s kubectl get pods -n cloudlena
microk8s kubectl get svc -n cloudlena
microk8s kubectl get virtualservice -n cloudlena
```

For more context, see the upstream project: https://github.com/cloudlena/s3manager
