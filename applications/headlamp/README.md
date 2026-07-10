# Headlamp deployment for MicroK8s

This directory installs Headlamp with the official Helm chart and applies two supporting Kubernetes resources:

- a cluster-admin service account and ClusterRoleBinding for login access
- an Istio VirtualService for ingress routing

## Prerequisites

- a working MicroK8s installation with Helm and kubectl available
- an Istio gateway named `istio-gateways/slainte-at` if you want to keep the VirtualService manifest

## Usage

Run the installer from this directory:

```bash
chmod +x headlamp.sh
./headlamp.sh
```

The script is idempotent. It removes any existing Headlamp release, reapplies the YAML manifests, and upgrades the Helm release.

## Configuration

The deployment is templated with environment variables so it can be reused across environments:

- `K8S_ENVIRONMENT`: suffix used in the default hostname (default: `dev`)
- `NAMESPACE`: namespace for the Headlamp resources (default: `kube-system`)
- `HEADLAMP_HOST`: hostname used by the VirtualService (default: `headlamp.${K8S_ENVIRONMENT}.slainte.at`)
- `WAIT_SECONDS`: Helm wait timeout in seconds (default: `180`)
- `RETRY_ATTEMPTS` / `RETRY_DELAY`: retry settings for kubectl operations
- `MICROK8S_CMD`: optional override for the MicroK8s CLI prefix, for example `sudo microk8s`

Example:

```bash
K8S_ENVIRONMENT=prod NAMESPACE=kube-system HEADLAMP_HOST=headlamp.example.com ./headlamp.sh
```

## Access

After the install completes, open the Headlamp UI using the configured hostname or the default `headlamp.<environment>.slainte.at` address.

To obtain a login token for the service account:

```bash
microk8s kubectl create token -n kube-system headlamp-admin
```

> The service account is granted cluster-admin privileges. Use it only for development, testing, or trusted environments.
