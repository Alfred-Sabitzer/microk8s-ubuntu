# Longhorn on MicroK8s

This setup installs [Longhorn](https://longhorn.io/) as a distributed block storage solution on MicroK8s using Helm.

## Prerequisites

- [MicroK8s](https://microk8s.io/) installed and running
- User in the `microk8s` group or root privileges
- `microk8s.helm3` enabled (`microk8s enable helm3`)
- Internet access to pull Helm charts and container images

## Usage

```bash
chmod +x MicroK8SLonghorn.sh
./MicroK8SLonghorn.sh
```

The script will:
- Ensure the `longhorn-system` namespace exists
- Add the Longhorn Helm repository
- Uninstall any previous Longhorn deployment
- Install Longhorn via Helm
- Wait for the UI deployment to be ready
- Optionally run a pod check script
- Apply the Ingress for the Longhorn UI

## Accessing the Longhorn UI

- The UI will be available at the hostname configured in your `longhorn-ingress.yaml` (e.g., `https://longhorn.slainte.at`).
- Ensure your DNS or `/etc/hosts` points the hostname to your cluster's ingress IP.

## Notes

- Edit `longhorn-ingress.yaml` to match your domain and TLS settings.
- For production, review Longhorn's [best practices](https://longhorn.io/docs/).

## Troubleshooting

- Check Longhorn pods:
  ```bash
  microk8s kubectl -n longhorn-system get pods
  ```
- Check Ingress:
  ```bash
  microk8s kubectl -n longhorn-system get ingress
  ```
- For more info, see [Longhorn documentation](https://longhorn.io/docs/).