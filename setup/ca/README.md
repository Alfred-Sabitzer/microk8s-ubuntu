# CA Setup for Internal Certificates

This setup creates a self-signed root CA and configures cert-manager ClusterIssuers for internal certificate management.

## References

- [CA Issuer](https://cert-manager.io/docs/concepts/issuer/)
- [CA List of Issuers](https://cert-manager.io/docs/configuration/issuers/)
- [CA Selfsigning](https://cert-manager.io/docs/configuration/selfsigned/)

## Prerequisites

- [MicroK8s](https://microk8s.io/) installed and running
- User in the `microk8s` group or root privileges
- `MicroK8S_Stop.sh` and `MicroK8S_Start.sh` scripts available and executable

## Usage

```bash
chmod +x ca.sh
./ca.sh
```

This script will:
- Apply the CA and issuer configuration from `ca.yaml`
- Retry if the API server is not ready

## Verifying the CA

Check the created secrets and issuers:

```bash
microk8s kubectl get secrets -n cert-manager
microk8s kubectl get clusterissuers
```
