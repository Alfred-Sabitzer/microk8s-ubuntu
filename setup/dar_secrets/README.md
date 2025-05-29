# Security Data at Rest for Kubernetes Secrets (MicroK8s)

This setup enables encryption at rest for Kubernetes secrets in MicroK8s.

## References

- [Kubernetes: Encrypt Data at Rest](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/)
- [Kubernetes Secrets in MicroK8s](https://devshell.io/kubernetes-secrets-in-microk8s)
- [Using a KMS provider for data encryption](ttps://kubernetes.io/docs/tasks/administer-cluster/kms-provider/#configuring-the-kms-provider-kms-v2)
h

## Prerequisites

- [MicroK8s](https://microk8s.io/) installed and running
- User in the `microk8s` group or root privileges
- `MicroK8S_Stop.sh` and `MicroK8S_Start.sh` scripts available and executable

## Usage

### 1. Enable Encryption

```bash
chmod +x dar_secrets.sh
./dar_secrets.sh
```

This script will:
- Generate a random encryption key
- Write the encryption config to MicroK8s
- Update the API server args
- Restart MicroK8s to apply changes
- Re-encrypt all existing secrets

### 2. Verify Encryption

```bash
chmod +x dar_secrets_check.sh
./dar_secrets_check.sh
```

This script will:
- Check if encryption is enabled
- Create a test secret
- Verify that the secret is encrypted at rest
- Clean up the test secret

## Troubleshooting

- Ensure you have the necessary permissions to write to MicroK8s directories.
- If you encounter permission errors, try running the scripts with `sudo`.
- Check MicroK8s status:  
  `microk8s status`



