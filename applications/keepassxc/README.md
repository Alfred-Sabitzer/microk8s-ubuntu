# KeePassXC → OpenBao / Kubernetes export

This folder contains a small workflow for converting KeePassXC entries into Kubernetes manifests and OpenBao-friendly secret payloads.

## What is included

- [keepass_to_eso_openbao.py](keepass_to_eso_openbao.py): exports KeePassXC entries into generated Kubernetes YAML and helper shell scripts.
- [keepassxc.sh](keepassxc.sh): bootstraps a Python virtualenv and installs the export dependencies.
- [secrets/keepassxc.sh](secrets/keepassxc.sh): uploads the generated OpenBao secrets into the cluster once OpenBao is reachable.
- [python.kdbx](python.kdbx): the example KeePassXC database used by the workflow.

## Workflow

1. Prepare a Python environment.
2. Export the database into manifest and helper files.
3. Review the generated manifests.
4. Apply the namespace / RBAC manifests if needed.
5. Run the OpenBao helper script to populate the secrets.

## Prerequisites

- Python 3.9+
- A KeePassXC database file such as [python.kdbx](python.kdbx)
- Access to a running MicroK8s cluster with OpenBao available
- The OpenBao root token exported as `OPENBAO_ROOT_TOKEN`

## Bootstrap

From this folder, run:

```bash
./keepassxc.sh
```

The wrapper creates a local virtualenv if needed and installs the required Python packages.

## Export secrets

Use the exporter with your KeePassXC database password:

```bash
KEEPASS_PASSWORD="your_database_password" \
./.venv/bin/python keepass_to_eso_openbao.py \
  --kdbx ./python.kdbx \
  --password "$KEEPASS_PASSWORD" \
  --outdir ./secrets \
  --mount kv \
  --prefix k8s
```

If you prefer, you can omit `--password` and set `KEEPASS_PASSWORD` in the environment.

## Generated output

The exporter writes:

- `secrets/<namespace>.yaml`: namespace, service account, role, and role binding manifests
- `secrets/<namespace>.sh`: helper shell script to push the corresponding secrets into OpenBao
- `secrets/<namespace>/<secret-name>.yaml`: generated Kubernetes secret manifests
- `secrets/errors.txt`: conversion problems, if any

## Entry mapping and custom fields

The exporter derives a namespace from the KeePassXC group path. The first folder under `Root` becomes the Kubernetes namespace, and the entry title becomes the secret name unless overridden.

Useful custom properties in KeePassXC entries:

- `k8s.ns`: override namespace
- `k8s.name`: override generated secret name
- `k8s.type`: one of `opaque`, `tls`, `dockerconfigjson`, `ssh`, `basicauth`, `serviceaccounttoken`
- `k8s.output`: `k8s` or `openbao`
- `k8s.sync`: `true` or `false`
- `k8s.labels`: comma-separated labels
- `k8s.annotations`: comma-separated annotations
- `openbao.mount`: OpenBao mount name
- `openbao.key`: key path relative to the mount
- `tls.crt`, `tls.key`, `ca.crt`
- `.dockerconfigjson` or `docker.server`, `docker.username`, `docker.password`, `docker.email`
- `ssh-privatekey`, `ssh-publickey`
- `username`, `password`
- `sa.name`

Any remaining custom field is stored in the secret payload as `prop_<key>` for opaque secrets.

## OpenBao upload

Once the exporter has generated the helper scripts, run:

```bash
OPENBAO_ROOT_TOKEN="<root-token>" ./secrets/keepassxc.sh
```

The wrapper checks that the OpenBao pod exists, logs in, and then runs each generated namespace helper script in this folder.

## Notes

- The exporter is intentionally conservative: it does not try to mutate your cluster automatically.
- `serviceaccounttoken` is supported for completeness, but Kubernetes usually populates those values via a controller rather than a static secret.
- Review the generated files before applying them to a cluster.
