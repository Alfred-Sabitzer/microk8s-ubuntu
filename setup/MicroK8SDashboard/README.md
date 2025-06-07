# MicroK8SDashboard

This script enables the Kubernetes Dashboard and configures Ingress for MicroK8s.

## Prerequisites

- [MicroK8s](https://microk8s.io/) installed and running
- User in the `microk8s` group or root privileges
- `dashboard-service-account.yaml` present in the same directory as the script

## Usage

```bash
chmod +x MicroK8SDashboard.sh
./MicroK8SDashboard.sh
```

The script will:
- Disable and re-enable the dashboard and its ingress to ensure a clean state
- Apply a `cluster-admin` service account for dashboard login
- Generate a long-lived token for dashboard authentication

## Accessing the Dashboard

1. Add the following to your `/etc/hosts` (replace IP as needed):

    ```
    192.168.10.104  kubernetes-dashboard.127.0.0.1.nip.io
    ```

2. Open [https://kubernetes-dashboard.127.0.0.1.nip.io](https://kubernetes-dashboard.127.0.0.1.nip.io) in your browser.

3. Use the generated token for login:

    ```bash
    microk8s kubectl create token cluster-admin -n kube-system --duration=8760h
    ```

    > **Note:** For MicroK8s <1.24, see [official docs](https://microk8s.io/docs/addon-dashboard).

## Security Note

- The `cluster-admin` role is highly privileged. For production, create service accounts with minimal permissions.

## Troubleshooting

- Ensure your user is in the `microk8s` group:  
  `sudo usermod -a -G microk8s $USER && newgrp microk8s`
- Check MicroK8s status:  
  `microk8s status`
- If you see permission errors, try running the script with `sudo`.

## YAML Files

- `dashboard-service-account.yaml`: Creates a `cluster-admin` service account and binding for dashboard login.
- `kubernetes-dashboard-ingress.yaml`: Configures Ingress for secure, local access to the dashboard. Edit the `host` and TLS settings as needed for your environment.

## Token Usage

The script will attempt to update your `~/.kube/config` with the generated token for dashboard access. If you have a custom kubeconfig, back it up before running the script.

## References

- [MicroK8s Dashboard Addon](https://microk8s.io/docs/addon-dashboard)
- [Kubernetes Dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)
