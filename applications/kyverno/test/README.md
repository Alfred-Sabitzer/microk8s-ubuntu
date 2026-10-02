# Kyverno test setup on MicroK8s

This directory contains the small test objects used to validate Kyverno policies for image provenance and registry enforcement.

## Layout

- `helm/`: Helm chart and helper scripts to deploy the dummy application into a dedicated namespace.
- `k8s/`: Kubernetes manifests for signed, unsigned, and wrong-repository image variants.
- `podman/`: script that builds and pushes the dummy images to Harbor and generates the signing helper script.
- `test_namespace/`: namespace, RBAC, and network policy fixtures used by the tests.

## Prerequisites

- A working MicroK8s or Kubernetes client (`kubectl` or `microk8s kubectl`)
- A Helm installation
- Access to an OCI registry such as Harbor
- Environment variables for the Harbor credentials:

```bash
export HARBOR_USER="<username>"
export HARBOR_PASSWORD="<password>"
```

## Typical workflow

1. Apply the namespace and access objects:

```bash
kubectl apply -f applications/kyverno/test/test_namespace/
```

2. Build and push the test image(s):

```bash
cd applications/kyverno/test/podman
HARBOR_USER="..." HARBOR_PASSWORD="..." ./do_test_podman.sh
```

3. Deploy the application with Helm:

```bash
cd applications/kyverno/test/helm
./helm_deploy.sh ./podman_kyverno-test_dummy_20261001.env
```

4. Test the policy result using the generated manifests in `k8s/`.

## Notes

- The scripts expect a Harbor-compatible registry and rely on secret names such as `harbor-cosign` in the target namespace.
- The generated helper scripts are intended for testing only and should not be used as-is in production.
- Use `--help` on the shell scripts for a quick usage overview.

