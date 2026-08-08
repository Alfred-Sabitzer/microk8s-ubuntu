# CA Setup for Internal Certificates

This folder contains the active CA helper for MicroK8s and a small set of helper scripts for certificate inspection and extraction.

## Purpose

- Create a cert-manager trusted root and intermediate CA inside the MicroK8s cluster.
- Export CA secrets to the local trusted certificate store.
- Provide helper scripts for inspecting and verifying issued certificates.

## Active files

- `ca.yaml` — cert-manager ClusterIssuer and Certificate resources for root and intermediate CA.
- `ca.sh` — apply `ca.yaml`, extract CA secrets, and update the local system trust store.
- `scripts/` — helper tools for certificate creation, inspection, and verification.

## Prerequisites

- MicroK8s installed and running.
- The `cert-manager` addon enabled in MicroK8s.
- Root or `sudo` privileges to update `/usr/local/share/ca-certificates`.
- `kubectl` configured through MicroK8s via `sudo microk8s kubectl`.

## Usage

1. Make the script executable:

```bash
chmod +x ca.sh
```

2. Run the CA setup:

```bash
./ca.sh
```

This script will:

- Apply the root and intermediate CA manifests from `ca.yaml`.
- Extract `cert-manager` CA secrets from the `cert-manager` namespace.
- Copy CA certificates into `/usr/local/share/ca-certificates`.
- Run `update-ca-certificates`.

## Verify setup

Check cert-manager resources:

```bash
sudo microk8s kubectl get clusterissuers
sudo microk8s kubectl get certificates -n cert-manager
```

Inspect extracted CA files:

```bash
sudo ls -1 /var/snap/microk8s/current/certs
sudo ls -1 /usr/local/share/ca-certificates
```

## Helper scripts

The `scripts/` directory contains tools for local certificate workflows.
Use `setup/ca/scripts/README.md` for full description and examples.

## Legacy content

The `archive/` directory contains older or experimental CA scripts and example manifests. Use it only for reference.
