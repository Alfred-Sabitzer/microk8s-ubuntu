# MicroK8S Observability Stack

This setup enables the MicroK8s Observability stack (Prometheus, Grafana, etc.) and configures secure Ingress for local access.

## Prerequisites

- [MicroK8s](https://microk8s.io/) installed and running
- User in the `microk8s` group or root privileges
- `cert-manager` and an appropriate ClusterIssuer (e.g., `k8s-issuer`) configured for TLS
- Ingress controller enabled (e.g., NGINX)

## Usage

```bash
chmod +x MicroK8SObersvability.sh
./MicroK8SObersvability.sh
```

The script will:
- Remove previous Ingress and dashboard resources
- Disable and re-enable the Observability addon
- Apply custom Ingress for Prometheus and Grafana dashboards
- Patch services to use LoadBalancer type
- Wait for all components to be ready

## Accessing Dashboards

- **Prometheus:**  
  https://k8s.prometheus.slainte.at

- **Grafana:**  
  https://k8s.grafana.slainte.at  
  Default credentials: `admin/prom-operator`

> Ensure your DNS or `/etc/hosts` points the above hostnames to your cluster's ingress IP.

## YAML Files

- `kube_prom_stack_kube_prome_operator_ingress.yaml`: Ingress for Prometheus dashboard with SSL, authentication, and DDoS protection.
- `kube_prom_stack_grafana.yaml`: Ingress for Grafana dashboard with SSL, authentication, and DDoS protection.

## Security Notes

- Basic authentication is enabled via `observability.basic-auth` secret. Change this secret for production.
- DDoS protection and source IP whitelisting are configured in the Ingress annotations.
- TLS is managed by cert-manager; ensure your ClusterIssuer and secrets are set up.

## Troubleshooting

- Check pod and service status:
  ```bash
  microk8s kubectl get pods,svc,ingress -n observability
  ```
- If you see permission errors, try running the script with `sudo`.
- For more info, see [MicroK8s Observability docs](https://microk8s.io/docs/addon-observability).

## References

- [MicroK8s Observability Addon](https://microk8s.io/docs/addon-observability)
- [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator)
- [Grafana](https://grafana.com/)
