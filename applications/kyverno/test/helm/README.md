# Helm chart for the Kyverno test workload

This chart deploys a small dummy application into a dedicated namespace for policy testing. The chart expects an OCI image reference and a digest from an environment file or shell variables.

## Required environment values

The helper script `helm_deploy.sh` sources an environment file exporting these variables:

- `HARBOR_LINK`: registry host, for example `harbor.test.slainte.at`
- `build`: builder tool, typically `podman`
- `tag`: image tag
- `project`: Harbor project
- `image`: image name
- `digest`: image digest, for example `sha256:...`

A sample file is included at `podman_kyverno-test_dummy_20261001.env`.

## Basic usage

```bash
cd applications/kyverno/test/helm
./helm_deploy.sh ./podman_kyverno-test_dummy_20261001.env
```

The script will:

- source the environment file
- validate the required variables
- detect `kubectl` or `microk8s kubectl`
- uninstall any previous release in the target namespace
- install or upgrade the chart with the configured image values

## Overrides

You can override the default namespace or command wrappers using environment variables:

```bash
TARGET_NAMESPACE="kyverno-test" HELM_CMD="sudo helm" ./helm_deploy.sh ./podman_kyverno-test_dummy_20261001.env
```

## Troubleshooting

- If the script exits with a missing-variable error, ensure the env file exists and exports all listed values.
- If `helm` or the Kubernetes client is not found, install the tool or adjust `HELM_CMD`/`KUBECTL_CMD` accordingly.
- Use `./helm_deploy.sh --help` to print the available usage summary.

