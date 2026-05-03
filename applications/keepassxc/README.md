# KeePassXC → ExternalSecrets / OpenBao export

A small helper for exporting KeePassXC entries from a `.kdbx` database into Kubernetes `ExternalSecret` manifests and OpenBao-compatible secret metadata.

This repository contains a Python script that reads KeePassXC entries with custom metadata and generates Kubernetes YAML files under `outdir/external-secrets/<namespace>/<name>.yaml`.

## What it does

- reads a KeePassXC `.kdbx` database using `pykeepass`
- converts entries into Kubernetes secret payloads
- supports multiple `k8s.type` values: `opaque`, `tls`, `dockerconfigjson`, `ssh`, `basicauth`, and `serviceaccounttoken`
- builds either a plain Kubernetes `Secret` or an `ExternalSecret` that references OpenBao-backed key/value entries
- writes output manifests into a folder structure by namespace
- records conversion errors to `errors.txt`

## Requirements

- Python 3
- `pykeepass`
- `pyyaml`
- a KeePassXC `.kdbx` file

## Setup

A helper script is included to prepare the environment:

```bash
cd /home/alfred/Alfred/Alfred/VSCode/microk8s-ubuntu/applications/keepassxc
source .venv/bin/activate
python -m pip install pykeepass pyyaml
```

You can also use the provided shell wrapper:

```bash
./keepassxc.sh
```

## Usage

Run the exporter with:

```bash
python keepass_to_eso_openbao.py \
    --kdbx ./python.kdbx \
    --password "your_database_password" \
    --outdir "./secrets" \
    --store-name "openbao" \
    --store-kind "ClusterSecretStore" \
    --refresh "1h" \
    --mount "kv" \
    --prefix "k8s" \
    --export-openbao "yaml"
```

If you prefer not to expose the password on the command line, set `KEEPASS_PASSWORD` in the environment instead of using `--password`.

## Output

- `outdir/external-secrets/<namespace>/<name>.yaml` — generated Kubernetes manifest files
- `outdir/errors.txt` — conversion issues and validation errors

## Folder and namespace mapping

The script derives the Kubernetes namespace from the KeePassXC entry folder structure:

- top-level group under `Root` becomes the namespace
- if no folder is available, the namespace falls back to `default`

Example:

- `Root / prod / payments` → namespace `prod`

## Custom KeePassXC properties

Place these settings in the KeePassXC entry custom fields to control manifest generation.

### Kubernetes / ESO settings

- `k8s.ns` — override the generated namespace
- `k8s.name` — override the secret name
- `k8s.type` — secret type
  - `opaque` (default)
  - `tls`
  - `dockerconfigjson`
  - `ssh`
  - `basicauth`
  - `serviceaccounttoken`
- `k8s.sync` — if openbao, then secret will be synced to corresponding k8s-secret
- `k8s.output` — output mode
  - `k8s` → plain Kubernetes `Secret`
  - `openbao` → `ExternalSecret` referencing OpenBao
- `eso.store` — ExternalSecrets store name
- `eso.storeKind` — store kind (`ClusterSecretStore` or `SecretStore`)
- `eso.refresh` — secret refresh interval
- `k8s.labels` — comma-separated labels to add
- `k8s.annotations` — comma-separated annotations to add

### OpenBao settings

- `openbao.mount` — OpenBao mount path
- `openbao.key` — OpenBao KV key path relative to the mount

### Secret-specific fields

- `tls.crt` / `tls.key` / `ca.crt`
- `.dockerconfigjson` or `docker.server`, `docker.username`, `docker.password`, `docker.email`
- `ssh-privatekey` / `ssh-publickey`
- `username` / `password` for basic-auth overrides
- `sa.name` for `serviceaccounttoken`

Any other custom property that does not begin with `k8s.`, `eso.`, `openbao.`, `sa.`, `docker.`, `tls.`, or `ssh.` will be copied into the `Opaque` secret payload as `prop_<key>`.

## Notes

- The script currently writes only manifest files and does not automatically push secrets into Kubernetes or OpenBao.
- `serviceaccounttoken` support is included for completeness, but such secrets are usually populated by Kubernetes controllers and may require additional platform-specific setup.

## Example

```bash
KEEPASS_PASSWORD="password" 
python keepass_to_eso_openbao.py \
  --kdbx python.kdbx \
  --outdir ./secrets \
  --store-name openbao \
  --store-kind ClusterSecretStore \
  --refresh 1h \
  --mount kv \
  --prefix k8s
```

## Contributing

If you update the script, please keep the README in sync with any new export logic or custom field names.

## License

This directory follows the repository license. If no license is present here, assume the same license used in the project root.
