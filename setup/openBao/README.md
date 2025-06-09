# OpenBao on MicroK8s

This setup installs [OpenBao](https://openbao.org/) on MicroK8s using the official Helm chart, configures secure Ingress, and manages unseal keys securely.

## Prerequisites

- [MicroK8s](https://microk8s.io/) installed and running
- User in the `microk8s` group or root privileges
- `microk8s helm` enabled (`microk8s enable helm3`)
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

## Troubleshooting

- Check OpenBao pods and services:
  ```bash
  microk8s kubectl get pods,svc -n openbao
  ```
- Check Ingress:
  ```bash
  microk8s kubectl get ingress -n openbao
  ```
- If you see permission errors, try running the script with `sudo`.

## References

- [OpenBao Documentation](https://openbao.org/docs/)
- [OpenBao Helm Chart](https://openbao.org/docs/platform/k8s/helm/)
