# Duplicity

This application creates encrypted Duplicity backups over SSH/SFTP. The
Helm chart deploys a Kubernetes `CronJob`; it does not run a permanent backup
pod.

The job:

1. mounts an existing bucket-backed PVC at `mounts.source`;
2. mounts the SSH destination with strict known-host verification;
3. creates or updates an incremental Duplicity backup;
4. removes backup sets older than `backup.retention` only after backup success.

## Prerequisites

- MicroK8s with Helm and the Secrets Store CSI driver
- OpenBao integration or another way to populate the configured CSI SecretProviderClasses
- `/dev/fuse` on eligible nodes
- an existing bucket-backed PVC whose name is `backup.bucket`
- an SSH user and directory with write permission
- a pre-generated `known_hosts` entry and an Ed25519 private key

The container is privileged because SSHFS/FUSE requires privileged device
access. Restrict namespace access and use dedicated cluster nodes or policy
rules where possible.

## Helm configuration

Render and review the chart first:

```sh
helm template test applications/duplicity/helm
microk8s helm upgrade --install test applications/duplicity/helm \
  --namespace duplicity --create-namespace
```

Important values:

| Value | Default | Purpose |
| --- | --- | --- |
| `backup.bucket` | `test-velero` | Source PVC and bucket name |
| `backup.s3Endpoint` | placeholder | Endpoint metadata; used only when direct s3fs mounting is enabled |
| `backup.s3Region` | `default` | S3 region metadata |
| `backup.fullIfOlderThan` | `1W` | Create a full backup when the last full backup is older |
| `backup.retention` | `2W` | Remove older backup chains after success |
| `cronJob.schedule` | `0 2 * * *` | UTC CronJob schedule |
| `mounts.sshRemotePath` | `/duplicity/test-velero` | Remote directory under the SSH account |
| `mounts.sshPort` | `22` | SSH/SFTP port |
| `mounts.backupPath` | `/mnt/remote/duplicity/test-velero` | Local SSHFS destination exposed to Duplicity |
| `credentials.backupSecretProviderClass` | `duplicity-backup-credentials` | CSI provider class |
| `credentials.sshSecretProviderClass` | `duplicity-ssh` | CSI provider class |
| `image.registry/project/repository/tag` | Harbor defaults | Container image location |
| `image.digest` | empty | Optional digest; when set it takes precedence over `tag` |

Create a local values override rather than committing environment-specific
settings:

```yaml
# duplicity-values.yaml
backup:
  bucket: my-backup-bucket
  s3Endpoint: https://s3.example.test
  s3Region: default

mounts:
  sshRemotePath: /backups/my-backup-bucket
  backupPath: /mnt/remote/backups/my-backup-bucket

image:
  registry: harbor.example.test
  project: operations
  repository: duplicity
  tag: "20261121"
```

Deploy:

```sh
microk8s helm upgrade --install test applications/duplicity/helm \
  --namespace duplicity --create-namespace \
  --values duplicity-values.yaml
```

## Credentials

The `duplicity-backup-credentials` SecretProviderClass expects these OpenBao
objects:

| Mounted file | Purpose |
| --- | --- |
| `url` | SSH server hostname |
| `username` | SSH/SFTP user |
| `password` | Duplicity passphrase |
| `gpg.private_key.asc` | Optional GPG private key import |

The `duplicity-ssh` SecretProviderClass requires:

| Mounted file | Purpose |
| --- | --- |
| `id_ed25519` | SSH private key |
| `known_hosts` | Verified server host key(s) |

Do not commit credentials or private keys. The SSH private key is mounted with
mode `0400`, and strict host-key checking is enabled. The known-host entry must
match the configured SSH host.

## Operations

Inspect the release:

```sh
microk8s kubectl get cronjob,jobs,pods -n duplicity
microk8s helm status test -n duplicity
```

Start a manual run:

```sh
microk8s kubectl create job --from=cronjob/test-duplicity \
  -n duplicity duplicity-manual
```

View a run:

```sh
microk8s kubectl logs -n duplicity job/duplicity-manual
```

Stopping or deleting a Job never deletes remote backup history. Removing the
temporary cache or the cache PVC does not remove Duplicity sets on the SSH
server.

## Restore

Restore on a trusted machine that has the passphrase and the same SSH
credentials:

```sh
PASSPHRASE='<passphrase>' duplicity \
  sftp://<user>@<host>/<remote-path> /restore/target
```

Use `--time` before the target to select a point in time. Keep the passphrase
outside the Kubernetes cluster; it is required to decrypt the backup.

## Validation

```sh
helm lint applications/duplicity/helm
helm template test applications/duplicity/helm
python3 -m unittest discover -s applications/duplicity/archive -p 'test_*.py'
shellcheck applications/duplicity/do_podman.sh \
  applications/duplicity/helm/helm_deploy.sh
```
