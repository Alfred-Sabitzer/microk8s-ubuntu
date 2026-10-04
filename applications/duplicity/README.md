# Duplicity backup of the `test-velero` bucket

This application runs a Kubernetes CronJob that mounts the S3-compatible
`test-velero` bucket with `s3fs-fuse`, then makes an encrypted Duplicity backup
to a remote directory mounted with SSHFS. It runs once per day at 02:00 UTC.
After a successful backup, Duplicity removes backup sets older than two weeks,
except older sets that are still required as a base for newer incrementals.
Backups are incremental, with a new full backup whenever the previous full is
more than one week old.

## Files

- `backup.py` mounts both filesystems, runs Duplicity, prunes old history, and
  unmounts on exit.
- `Dockerfile` builds the image with Python, Duplicity, `s3fs`, SSHFS, and FUSE.
- `helm/` contains the Helm chart for deploying and configuring the CronJob.
- `test_backup.py` contains unit tests for configuration validation and backup
  retention ordering.

## Requirements and security

- The Kubernetes nodes need `/dev/fuse`, and cluster policy must allow the
  CronJob's privileged container. FUSE mounts are why the pod is privileged.
  This grants the container broad access to the node; use a trusted cluster and
  restrict who can edit or run workloads in the `duplicity` namespace.
- The pod needs network access to the S3 endpoint and SSH server.
- The SSH server must allow SFTP/SSHFS access, and its host key must be present
  in the `known_hosts` file supplied to the pod. Host key checking is strict;
  the job will not accept unknown or changed host keys.
- The SSH remote directory must already exist and be writable by the configured
  SSH user.
- The S3 endpoint and region in the chart default to the values used by the
  Velero setup in this repository. Adjust them if `test-velero` uses a different
  object-storage endpoint.

## Credentials

Create the following Kubernetes Secret in namespace `duplicity` using your
secret-management system (for example, the existing External Secrets/OpenBao
integration). Do not commit credential values:

| Secret key | Purpose |
| --- | --- |
| `s3-access-key` | S3 access key for `test-velero` |
| `s3-secret-key` | S3 secret key |
| `gpg-passphrase` | Duplicity symmetric-encryption passphrase |
| `ssh-host` | SSH server hostname or IP address |
| `ssh-user` | SSH account that can write the backup directory |
| `ssh-remote-path` | Existing directory on the SSH server |
| `ssh-port` | Optional SSH port (defaults to 22) |

Create another Secret named `duplicity-ssh` with these files:

- `id_ed25519`: the private key for the SSH account (a different key filename
  can be used only if `SSH_KEY_FILE` is changed in the pod).
- `known_hosts`: a pre-verified host-key entry for the SSH server.

Mount the private key with mode `0400`. For example, the contents can be
prepared in a secured admin environment and passed to:

```sh
microk8s kubectl create secret generic duplicity-ssh -n duplicity \
  --from-file=id_ed25519=/secure/path/id_ed25519 \
  --from-file=known_hosts=/secure/path/known_hosts
```

Create `duplicity-backup-credentials` with the listed keys using your secret
manager. The pod consumes those key names directly. Do not put private keys,
passphrases, or access keys in this repository or shell history.

## Build and deploy

Build the image and publish it to a registry accessible to the cluster:

```sh
docker build -t <registry>/duplicity-backup:<tag> applications/duplicity
docker push <registry>/duplicity-backup:<tag>
```

Create a Helm values file for the image and credentials Secret references, or
override them on the command line. Create the namespace and install the chart:

```sh
microk8s helm upgrade --install test-velero-duplicity \
  applications/duplicity/helm \
  --namespace duplicity \
  --create-namespace \
  --set image.repository=<registry>/duplicity-backup \
  --set image.tag=<tag>
```

The chart defaults expect credentials named `duplicity-backup-credentials` and
SSH files in `duplicity-ssh`, both in the Helm release namespace. These Secrets
must exist before the CronJob starts. To customize schedule, retention,
storage endpoint, secret names/keys, or image settings, create a values file
and pass it with `--values /path/to/values.yaml`. See
[`helm/values.yaml`](helm/values.yaml) for the available chart values.

Review the configured endpoint and ensure your cluster's Pod Security policy
admits the privileged pod with `/dev/fuse`.

## Configuration

The Helm chart configures the S3 endpoint, region, bucket, and secret
references. Optional environment variables supported by `backup.py` are:

| Variable | Default | Description |
| --- | --- | --- |
| `S3_BUCKET` | `test-velero` | Bucket mounted by s3fs |
| `SSH_PORT` | `22` | SSH server port |
| `SSH_KEY_FILE` | `/run/ssh/id_ed25519` | Mounted SSH private-key path |
| `SSH_KNOWN_HOSTS_FILE` | `/run/ssh/known_hosts` | Strict SSH host-key file |
| `SOURCE_MOUNT` | `/mnt/source` | s3fs mount location |
| `DESTINATION_MOUNT` | `/mnt/remote` | SSHFS mount location |
| `DESTINATION_PATH` | `/mnt/remote/duplicity/test-velero` | Duplicity archive directory |
| `DUPLICITY_FULL_IF_OLDER_THAN` | `1W` | Full backup interval |
| `DUPLICITY_RETENTION` | `2W` | Remove older backup chains after success |
| `DUPLICITY_ARCHIVE_DIR` | `/tmp/duplicity-cache` | Local Duplicity metadata/cache |

`GPG_PASSPHRASE` is supplied from the credentials Secret and used for symmetric
encryption. Store it securely: restoring a backup requires this passphrase.
Keep an independent copy of the passphrase outside the cluster.

## Operations

Check job and pod status:

```sh
microk8s kubectl get cronjob,jobs,pods -n duplicity
microk8s kubectl logs -n duplicity job/<job-name>
```

Trigger an immediate one-off run:

```sh
microk8s kubectl create job --from=cronjob/test-velero-duplicity \
  -n duplicity test-velero-duplicity-manual
```

The job uses `concurrencyPolicy: Forbid` to prevent overlapping backups.
Retention is run only after Duplicity completes the backup successfully.
Deleting the pod's `emptyDir` cache does not delete remote history; Duplicity
uses the remote archive as the source of truth.

To restore, mount the same SSHFS destination and set `PASSPHRASE` to the
`gpg-passphrase` value from the Secret. Duplicity restores the latest point into
the target directory:

```sh
PASSPHRASE='<retrieve securely from your secret manager>' \
  duplicity file:///mnt/remote/duplicity/test-velero /restore/target
```

Use Duplicity's `--time` option to restore a different point in time. Keep the
encryption passphrase available independently of the cluster; without it the
backup cannot be decrypted.

Run unit tests locally with Python 3:

```sh
python3 -m unittest discover -s applications/duplicity -p 'test_*.py'
```
