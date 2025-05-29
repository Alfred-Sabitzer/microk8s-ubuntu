# Vault on MicroK8s

This setup deploys [HashiCorp Vault](https://github.com/hashicorp/vault) on MicroK8s using the official Helm chart.

## References

- [Vault Documentation](https://developer.hashicorp.com/vault)
- [Vault Helm Deployment Guide](https://developer.hashicorp.com/vault/docs/deploy/kubernetes/helm)

## Prerequisites

- [MicroK8s](https://microk8s.io/) installed and running
- User in the `microk8s` group or root privileges
- [Helm](https://helm.sh/) installed

## Usage

```bash
chmod +x vault.sh
./vault.sh
```

The script will:
- Create a `vault` namespace
- Add the HashiCorp Helm repository (if not already present)
- Install Vault in development mode (INSECURE, for testing only)

## Accessing Vault

1. Forward the Vault UI port:
    ```bash
    microk8s kubectl port-forward svc/vault 8200:8200 --namespace vault
    ```
2. Open [http://localhost:8200](http://localhost:8200) in your browser.

## Important Notes

- **Development mode is NOT secure.** Do not use in production.
- For production, configure Vault with proper authentication and storage backends.

## Cleanup

```bash
microk8s helm uninstall vault --namespace vault
microk8s kubectl delete namespace vault
helm repo remove hashicorp
```

## Troubleshooting

- Check Vault pods:
  ```bash
  microk8s kubectl get pods --namespace vault
  ```
- Check Vault service:
  ```bash
  microk8s kubectl get svc --namespace vault
  ```



