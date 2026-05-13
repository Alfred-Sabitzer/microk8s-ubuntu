
# keepassxc Tests

This folder contains a minimal validation environment for OpenBao CSI integration with Kubernetes.

## Files

- `keepassxc.yaml` – deploys a namespace and a busybox test Deployment.

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

This files are in the test-directory

```bash
chmod +x openbaotest_setup.sh
./openbaotest_setup.sh
```

3. Deploy the test application:

```bash
sudo microk8s kubectl apply -f keepassxc.yaml
```

4. Verify the mounted secrets:

```bash
sudo microk8s kubectl -n keepassxc get pods
sudo microk8s kubectl -n keepassxc exec -it deploy/keepassxc -- ls -R /mnt/
```

5. Cleanup:

```bash
sudo microk8s kubectl delete -f keepassxc.yaml
```

## Notes

- The test manifest creates an in-cluster `SecretProviderClass` and syncs the secret into Kubernetes.
- The role name in the test manifest must match the OpenBao role created by the testscripts.
- For production use, tighten the RBAC rules and avoid using root tokens in scripts.
