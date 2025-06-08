# MicroK8S Ingress Controller

This script enables the NGINX Ingress controller for MicroK8s, allowing you to expose services via HTTP/S routes.

## Prerequisites

- [MicroK8s](https://microk8s.io/) installed and running
- User in the `microk8s` group or root privileges

## Usage

```bash
chmod +x MikroK8SIngress.sh
./MikroK8SIngress.sh
```

The script will:
- Disable and re-enable the Ingress controller to ensure a clean state
- Wait for the controller to be ready

## Verifying Ingress

Check the status of the ingress controller:

```bash
microk8s kubectl get pods -n ingress
microk8s kubectl get svc -n ingress
```

## Customization

- You can configure your own Ingress resources to expose services.  
  See [Kubernetes Ingress documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/) for examples.

## Troubleshooting

- Ensure your user is in the `microk8s` group:  
  `sudo usermod -a -G microk8s $USER && newgrp microk8s`
- Check MicroK8s status:  
  `microk8s status`
- If you see permission errors, try running the script with `sudo`.

## References

- [MicroK8s Ingress Addon](https://microk8s.io/docs/addon-ingress)
- [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [NGINX Ingress Controller Docs](https://kubernetes.github.io/ingress-nginx/)
