# OpenBao CSI Test

This folder contains a minimal validation environment for OpenBao CSI integration with Kubernetes.

## Files

- `openbaotest.yaml` – deploys a namespace, ServiceAccount, RBAC, SecretProviderClass, and a busybox test Deployment.
- `openbaotest_setup.sh` – populates OpenBao with a test secret, policy, and Kubernetes auth role.

## Prerequisites

- OpenBao is deployed and accessible inside the cluster at `http://openbao.openbao.svc:8200`.
- The OpenBao CSI provider is installed and configured.
- `OPENBAO_ROOT_TOKEN` is exported before running `openbaotest_setup.sh`.
- `sudo microk8s kubectl` is available.

## Usage

1. Set the OpenBao root token:

```bash
export OPENBAO_ROOT_TOKEN="<your-root-token>"
```

2. Prepare OpenBao for the test:

```bash
chmod +x openbaotest_setup.sh
./openbaotest_setup.sh
```

3. Deploy the test application:

```bash
sudo microk8s kubectl apply -f openbaotest.yaml
```

4. Verify the mounted secret:

```bash
sudo microk8s kubectl -n openbaotest get pods
sudo microk8s kubectl -n openbaotest exec -it deploy/openbaotest -- ls -R /mnt/
```

5. Cleanup:

```bash
sudo microk8s kubectl delete -f openbaotest.yaml
```

## Notes

- The test manifest creates an in-cluster `SecretProviderClass` and syncs the secret into Kubernetes.
- The role name in the test manifest is `openbaotest-role` and must match the OpenBao role created by `openbaotest_setup.sh`.
- For production use, tighten the RBAC rules and avoid using root tokens in scripts.
