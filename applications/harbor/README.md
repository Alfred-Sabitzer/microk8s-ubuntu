# Harbor deployment on MicroK8s

This directory contains a small Harbor deployment set for MicroK8s. It combines a few Kubernetes manifests with a wrapper script that installs the Harbor Helm chart and applies the supporting resources in a consistent order.

## What is included

- [harbor.sh](harbor.sh) installs or refreshes Harbor in a namespace of your choice and applies the YAML files in this directory.
- [10_harbor_namespace.yaml](10_harbor_namespace.yaml) creates the target namespace.
- [20_harbor-virtual-service-mutual.yaml](20_harbor-virtual-service-mutual.yaml) exposes Harbor through the Istio gateway.
- [30_harbor_monitoring.yaml](30_harbor_monitoring.yaml) defines a ServiceMonitor for Prometheus scraping.
- [40_harbor_manifest.yaml](40_harbor_manifest.yaml) provisions Harbor-related RBAC objects.
- [secretadminpassword.yaml](secretadminpassword.yaml), [registrysecret.yaml](registrysecret.yaml), and [registrycredentials.yaml](registrycredentials.yaml) define the pre-existing secrets that Harbor expects.

## Prerequisites

Before running the script, make sure that:

- MicroK8s is installed and the current user can run it.
- The required binaries are available: `envsubst`, `find`, `kubectl`, `helm`.
- The target namespace is valid and the storage class you use exists.
- An Istio gateway and the monitoring stack are available if you keep the virtual service and ServiceMonitor manifests.

## Usage

Run the installer from this directory:

```bash
./harbor.sh
```

The script supports the following environment variables:

- `NAMESPACE`: target namespace for Harbor resources (default: `harbor`)
- `K8S_ENVIRONMENT`: suffix used when building the default hostname (default: `test`)
- `HARBOR_HOSTNAME`: fully qualified hostname for Harbor (default: `harbor.${K8S_ENVIRONMENT}.slainte.at`)
- `HARBOR_STORAGE_CLASS`: storage class used by the Helm chart (default: `cephfs`)
- `WAIT_SECONDS`: Helm timeout in seconds (default: `180`)
- `RETRY_ATTEMPTS`: retries for apply/delete steps (default: `5`)
- `RETRY_DELAY`: delay between retries in seconds (default: `5`)
- `MICROK8S_CMD`: override for the MicroK8s CLI call, for example `sudo microk8s`

Example:

```bash
NAMESPACE=harbor \
K8S_ENVIRONMENT=prod \
HARBOR_HOSTNAME=harbor.prod.example.com \
HARBOR_STORAGE_CLASS=ceph-rbd \
./harbor.sh
```

## Notes on robustness

- The script uses `set -euo pipefail` and retries YAML apply/delete operations to make transient failures less disruptive.
- The manifests consume environment variables through `envsubst`, so the namespace and hostname can be adjusted without editing the YAML files directly.
- The script reuses the same namespace and storage class settings for both the Helm deployment and the supporting Kubernetes resources.
- The secret manifests are intentionally simple placeholders and should be reviewed, rotated, and replaced with your real values before production use.

## Troubleshooting

- If the script exits early, inspect the command output for the failing `kubectl` or `helm` step.
- If Harbor is not reachable, verify that the DNS name resolves and that the Istio gateway is configured for the chosen host.
- If the chart cannot bind storage, confirm that the selected storage class exists and supports the requested access mode.

## References

- https://github.com/goharbor/harbor
- https://goharbor.io/
- https://goharbor.io/docs/2.15.0/install-config/harbor-ha-helm/
- https://www.fortaspen.com/harbor-image-registry-for-docker-podman-kubernetes/
- https://artifacthub.io/packages/container/harbor-cli/harbor-cli
- https://api.harbor.gg/docs/index.html




