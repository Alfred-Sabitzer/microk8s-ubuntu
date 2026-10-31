# Rook Ceph toolbox

This directory contains a modified Rook toolbox Deployment for debugging an
external Ceph cluster from MicroK8s. The Deployment runs in
`rook-ceph-external` and uses the admin Secret and endpoint ConfigMap prepared
by `rook_toolbox.sh`.

## Prerequisites

- MicroK8s is running and its Rook external-cluster setup is already installed
  in the `rook-ceph-external` namespace.
- That namespace contains the `rook-ceph-default` ServiceAccount.
- `sudo microk8s kubectl` works for the account running the script.
- `K8S_ENVIRONMENT` must be set to the name of a readable
  `/etc/ceph/vars_<name>.sh` file. The file must define:
  - `ROOK_EXTERNAL_FSID`
  - `MONITORING_ENDPOINT` — the Ceph monitor host (IPv4 address or DNS name),
    without a scheme or port
  - `MONITORING_ENDPOINT_PORT` — the monitor's TCP port, from 1 through 65535
- `/etc/ceph/ceph.keyring` is readable and contains a `[client.admin]` section
  with a `key = ...` entry.

The variables file is sourced as shell code. Keep it trusted and restrict its
permissions; do not commit it or the keyring to source control.

## Install or update

From this directory, run the script as a user who can use `sudo`:

```bash
K8S_ENVIRONMENT=production bash ./rook_toolbox.sh
```

Replace `production` with the name used in `/etc/ceph/vars_<name>.sh`.
The script validates its inputs, applies or updates the admin Secret and
endpoint ConfigMap, applies the checked-in `rook_toolbox.yaml`, and waits up to
five minutes for the toolbox pod to become Ready. Re-running it is supported.
It does not download manifests or interpolate host environment variables into
the embedded shell script in the YAML.

## Verify and use

```bash
sudo microk8s kubectl -n rook-ceph-external get deployment,pods
sudo microk8s kubectl -n rook-ceph-external logs deployment/rook-ceph-tools
sudo microk8s kubectl -n rook-ceph-external exec deployment/rook-ceph-tools -- ceph -s
```

For an interactive shell:

```bash
sudo microk8s kubectl -n rook-ceph-external exec -it deployment/rook-ceph-tools -- bash
```

The toolbox container includes Ceph command-line tools and reads its Ceph
configuration and keyring from the mounted Secret and ConfigMap.

## Security and cleanup

The toolbox uses `client.admin`, a highly privileged Ceph identity. Keep access
to the namespace and pod restricted, do not expose the toolbox externally, and
remove it when debugging is complete if it is not needed continuously.

Remove only the toolbox resources with:

```bash
sudo microk8s kubectl -n rook-ceph-external delete deployment rook-ceph-tools
sudo microk8s kubectl -n rook-ceph-external delete secret rook-ceph-admin
sudo microk8s kubectl -n rook-ceph-external delete configmap rook-ceph-admin-endpoints
```
