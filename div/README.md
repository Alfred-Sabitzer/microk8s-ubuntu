# Utility scripts

This directory contains standalone shell utilities for Kubernetes and host
maintenance. They are independent of the larger deployment scripts in other
directories.

## Requirements

- Bash 4 or newer
- `kubectl`, or a working MicroK8s installation
- `sudo` for MicroK8s or privileged disk access
- `jq` for namespace cleanup and standalone-pod detection
- `base64` for directory-based ConfigMap generation

Set `KUBECTL_BIN` to use a different kubectl command or wrapper:

```bash
export KUBECTL_BIN=/usr/local/bin/kubectl
```

All scripts support `-h` or `--help`.

## Scripts

### `crds.sh`

Exports all custom resource definitions to one YAML file per CRD.

```bash
./crds.sh
./crds.sh ./crd-export
```

The output directory is created when necessary. The script writes files named
after the CRD, for example `certificates.cert-manager.io.yaml`.

### `make_configmap.sh`

Creates a ConfigMap YAML document from one source file.

```bash
./make_configmap.sh /etc/ssh/sshd_config ./sshd-config.yaml
./make_configmap.sh ./app.conf ./app.yaml my-app-config
```

The optional third argument sets `metadata.name`. If omitted, the script derives
a name from the source file and also derives a ConfigMap data key from the
source basename.

### `make_configmap_dir.sh`

Creates a ConfigMap YAML document from regular files directly inside a
directory. It places common text formats in `data` and other files in
`binaryData` as Base64.

```bash
./make_configmap_dir.sh ./config ./my-config.yaml
./make_configmap_dir.sh ./config ./my-config.yaml my-app-config
```

Only files directly in the source directory are included; subdirectories are
not traversed. Invalid ConfigMap key characters are replaced with `-`.

### `namespace_delete.sh`

Safely inspects a stuck namespace and, only with `--force`, removes finalizers
and asks for confirmation before attempting finalization.

```bash
./namespace_delete.sh test
./namespace_delete.sh test --force
```

The default mode is a dry run. Protected Kubernetes namespaces are refused.
The force operation removes all finalizers from namespaced resources and from
the namespace itself, so use it only after backing up or otherwise resolving
controller-specific cleanup requirements.

### `namespace_restart.sh`

Restarts Deployments, StatefulSets, and DaemonSets in a namespace. It defaults
to dry-run mode only when `--dry-run` is supplied and otherwise requires
interactive confirmation unless `--yes` is used.

```bash
./namespace_restart.sh observability
./namespace_restart.sh observability --dry-run
./namespace_restart.sh observability --yes
./namespace_restart.sh observability --wait 600
./namespace_restart.sh observability --delete-standalone-pods --yes
```

After restart, rollout status is checked. Standalone pod deletion is opt-in.

### `services_pods.sh`

Lists the pods selected by every Service in all namespaces or in one namespace.

```bash
./services_pods.sh
./services_pods.sh observability
./services_pods.sh --namespace observability
```

Services without a pod selector are reported explicitly.

### `space.sh`

Displays `df` output followed by disk usage for direct subdirectories of a
filesystem path.

```bash
./space.sh
./space.sh /var
```
