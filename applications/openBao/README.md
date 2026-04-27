# OpenBao on MicroK8s

This directory contains a MicroK8s deployment helper for OpenBao and a small OpenBao CSI integration test.

## Overview

- `openBao.sh` - installs and configures OpenBao on MicroK8s using Helm.
- `openBao_setup.sh` - configures OpenBao policy/auth for a test namespace and enables the KV engine. Intended for demo/test use.
- `kexec.sh` - helper to open a shell into an OpenBao pod.
- `openbao_dashboards.sh` - downloads Grafana dashboards from grafana.com and creates ConfigMaps for Grafana provisioning.
- `test/openbaotest.yaml` - Kubernetes manifest to validate OpenBao CSI secret mounts and secret sync.
- `test/openbaotest_setup.sh` - populates OpenBao with a secret, policy, and Kubernetes auth role for the test environment.

## Requirements

- MicroK8s installed and running
- `microk8s helm` enabled
- `microk8s kubectl` available via `sudo microk8s kubectl`
- `yq` installed for `openbao_dashboards.sh`
- `OPENBAO_ROOT_TOKEN` set for OpenBao login in `openBao_setup.sh` and `test/openbaotest_setup.sh`

## Installing OpenBao

Run the installer script from this directory:

```bash
chmod +x openBao.sh
./openBao.sh
```

The script uses a generated `/tmp/openbao-values.yaml` file and deploys the OpenBao Helm chart. It also applies YAML resources found in this directory.

## Notes

- `openBao.sh` defaults `K8S_ENVIRONMENT` to `dev` when unset.
- The script will print the UI host using `OPENBAO_UI_HOST` or `openbao.${K8S_ENVIRONMENT}.slainte.at`.
- The Helm install and Kubernetes resource application steps now use safer quoting and envsubst handling.

## Test environment

The `test/` directory contains a quick OpenBao CSI validation manifest.

1. Configure OpenBao with a root token:

```bash
export OPENBAO_ROOT_TOKEN="<your-root-token>"
chmod +x test/openbaotest_setup.sh
./test/openbaotest_setup.sh
```

2. Deploy the test workload:

```bash
sudo microk8s kubectl apply -f test/openbaotest.yaml
```

3. Verify the pod and mounted secret volume:

```bash
sudo microk8s kubectl -n openbaotest get pods
sudo microk8s kubectl -n openbaotest exec -it deploy/openbaotest -- ls -R /mnt/
```

4. Cleanup:

```bash
sudo microk8s kubectl delete -f test/openbaotest.yaml
```

## Dashboard provisioning

Run `openbao_dashboards.sh` to download dashboard JSON from Grafana and create ConfigMaps in the `observability` namespace.

```bash
chmod +x openbao_dashboards.sh
./openbao_dashboards.sh
```

## Security

This repository is intended for development and testing.

- Do not store OpenBao unseal keys or root tokens in ConfigMaps or files for production use.
- The test helpers create broad demo credentials and should be hardened before use in a real deployment.

## Files

- `01_openbao_namespace.yaml` - namespace manifest
- `05_certs.yaml` - certificate resources
- `10_openBao_Cluster_role.yaml` - cluster role definitions
- `15_openbao_secrets.yaml` - secret definitions
- `20_virtual-service-openbao-mutual.yaml` - ingress/mutual TLS manifest
- `openBao.sh` - main OpenBao installer
- `openBao_setup.sh` - OpenBao policy/auth setup helper
- `openbao_dashboards.sh` - Grafana dashboard provisioning helper
- `kexec.sh` - pod shell helper
- `test/openbaotest.yaml` - OpenBao CSI integration test manifest
- `test/openbaotest_setup.sh` - OpenBao test policy/secret setup script
