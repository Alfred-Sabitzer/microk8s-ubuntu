# OpenBao on MicroK8s

This setup installs [OpenBao](https://openbao.org/) on sudo microk8s using the official Helm chart, configures secure Ingress, and manages unseal keys securely.

## Prerequisites

- [MicroK8s](https://microk8s.io/) installed and running
- User in the `microk8s` group or root privileges
- `sudo microk8s helm` enabled (`sudo microk8s enable helm3`)
- `openbao-values.yaml` present in the same directory (customize as needed)
- Ingress controller enabled (e.g., NGINX)
- `cert-manager` and a ClusterIssuer (e.g., `k8s-issuer`) for TLS

## Usage

```bash
chmod +x openBao.sh
./openBao.sh
```

The script will:
- Add the OpenBao Helm repository (if not present)
- Uninstall any previous OpenBao release and clean up related resources
- Install OpenBao using your `openbao-values.yaml`
- Initialize and unseal OpenBao, storing unseal keys in a ConfigMap
- Apply the Ingress for secure access

## Accessing OpenBao

- The UI will be available at:  
  https://k8s.openbao.slainte.at  
  (Edit `openbao-ingress.yaml` to match your domain and TLS settings.)

## Security Notes

- Unseal keys and the initial root token are stored in a ConfigMap (`openbao-unseal-config`) in the `openbao` namespace. **This is not secure for production!**  
  For production, store unseal keys securely outside the cluster.
- The Ingress restricts access to local/private networks and rate-limits requests.

## YAML Files

- `openbao-values.yaml`: Helm values for OpenBao deployment. Customize for your environment.
- `openbao-ingress.yaml`: Ingress for secure, local access to OpenBao. Edit `host`, `tls`, and `whitelist-source-range` as needed.

## Scripts

- `openBao.sh`: Installs and configures OpenBao, initializes and unseals the vault, and applies Ingress.
- `openBao_unseal.sh`: Unseals OpenBao using keys from the ConfigMap. For demo/dev only.
- `openBao_unseal_cron.sh`: Sets up a cron job to periodically unseal OpenBao. Only install on one node.

## Testing

After running the setup, access the UI at your configured Ingress host (default: https://k8s.openbao.slainte.at).  
Log in with the initial root token from the ConfigMap (`openbao-unseal-config` in the `openbao` namespace).

## Testing OpenBao CSI Integration

The `test/openbaotest.yaml` manifest deploys a test environment to verify that secrets from OpenBao can be mounted into a pod using the Secrets Store CSI driver.

### Prerequisites

- OpenBao is running and accessible at `https://openbao.openbao.svc:8200`
- The `kv-role` exists in OpenBao and is configured for the test namespace
- The referenced certificate files are available in the cluster
- The Secrets Store CSI driver is installed and configured

### Deploy the Test

```bash
sudo microk8s kubectl apply -f test/openbaotest.yaml
```

### Verify

Check that the pod is running and the secret is mounted:

```bash
sudo microk8s kubectl -n test get pods
sudo microk8s kubectl -n test exec -it deploy/openbaotest -- ls /mnt/secrets-store
```

### Cleanup

```bash
sudo microk8s kubectl delete -f test/openbaotest.yaml
```

### Notes

- The ServiceAccount and RBAC are minimal for this test. For production, restrict permissions as needed.
- The commented-out ClusterRoleBindings are examples and can be enabled if your setup requires them.

## Security Warning

- **Never use ConfigMap-based unseal key storage or automated unseal in production.**  
  Always store unseal keys and root tokens securely outside the cluster.

## Troubleshooting

- Check OpenBao pods and services:
  ```bash
  sudo microk8s kubectl get pods,svc -n openbao
  ```
- Check Ingress:
  ```bash
  sudo microk8s kubectl get ingress -n openbao
  ```
- If you see permission errors, try running the script with `sudo`.

## Cleanup

To remove OpenBao and related resources:
```bash
sudo microk8s helm uninstall openbao --namespace openbao
sudo microk8s kubectl delete namespace openbao
```

## References

- [OpenBao Documentation](https://openbao.org/docs/)
- [OpenBao Helm Chart](https://openbao.org/docs/platform/k8s/helm/)
- [Explain K8S Secrets](https://spacelift.io/blog/kubernetes-secrets)
- [Funny Video](https://www.youtube.com/watch?v=OFRj0gyKJkw)
- [Get an Idea](https://milan-pandey.medium.com/setting-up-an-external-openbao-server-for-kubernetes-eks-secrets-with-vault-secrets-operator-vso-bc02eb3ab53d)
- [Useful examples](https://github.com/openbao/openbao-csi-provider/tree/main/test/bats)


