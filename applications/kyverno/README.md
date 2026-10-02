# Kyverno deployment on MicroK8s

This directory contains the project-level deployment assets for Kyverno on a MicroK8s cluster.

## Contents

- `kyverno.sh`: installs and refreshes the Kyverno Helm release and applies the local YAML resources in this directory.
- `10_kyverno_namespace.yaml`: namespace definition for the Kyverno installation.
- `20_kyverno_rule_namespace.yaml`: namespace-wide policy/rule bootstrap for testing or validation scenarios.
- `test/`: dedicated Kyverno test workloads, image fixtures, and small helper scripts for signed/unsigned image validation.
- `archiv/`: historical Helm chart and templates kept for reference.

## Prerequisites

- A working MicroK8s cluster or a Kubernetes cluster with `kubectl` access
- `helm`
- `envsubst`
- `find`
- Access to the `kyverno` namespace or a namespace override via environment variables

## Typical usage

```bash
cd applications/kyverno
MICROK8S_CMD="sudo microk8s" ./kyverno.sh
```

Optional overrides:

```bash
export NAMESPACE="kyverno"
export K8S_ENVIRONMENT="test"
export WAIT_SECONDS="180"
export RETRY_ATTEMPTS="5"
export RETRY_DELAY="5"
export HELM_REPO_URL="https://kyverno.github.io/kyverno/"
export HELM_RELEASE_NAME="kyverno"
./kyverno.sh
```

## Notes

- The script tries to uninstall any existing Kyverno release before re-applying the local manifests.
- It validates YAML files in the current directory before installing the Helm chart.
- For policy-testing workflows, refer to the scripts under [applications/kyverno/test](applications/kyverno/test).
- The project defaults are designed for testing and validation rather than a hardened production deployment.

