# Quick Start — Istio VirtualServices (MicroK8s)

This quick guide shows the minimal steps to deploy the YAMLs and scripts in this directory.

Prerequisites
- A working Kubernetes context (microk8s or kubectl) with access to the cluster
- `envsubst` (from `gettext-base`) installed if you rely on `${K8S_ENVIRONMENT}` substitutions
- `kubectl` or `microk8s kubectl` available in PATH

Steps
1. Export your environment name used in hostnames (example):

```bash
export K8S_ENVIRONMENT=staging
```

2. Make the utility scripts executable:

```bash
chmod +x *.sh
```

3. Deploy virtual services from this directory (recommended):

```bash
# Apply all YAMLs found in the current directory, with envsubst applied
./virtual_services.sh ./ --wait 60
```

4. To remove the resources created here:

```bash
./delete_yaml.sh ./
```

Validation

```bash
# Basic syntax checks
bash -n virtual_services.sh
yamllint -c /etc/xdg/yamllint/config .

# Kubernetes dry-run (requires cluster access)
kubectl apply -f 01_virtual-service-grafana-mutual.yaml --dry-run=client
```

If you see errors about `kubectl` not found, run the scripts with the full path to `microk8s kubectl` or install `kubectl`.
