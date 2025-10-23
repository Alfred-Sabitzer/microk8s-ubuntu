# MicroK8s Ingress Controller

This script enables the NGINX Ingress controller on MicroK8s and performs basic readiness checks.

## Project overview
The script ensures the MicroK8s ingress addon is enabled and attempts a clean start by disabling the addon first (optional). It waits for the ingress pods and services to become available.

## Prerequisites
- MicroK8s installed and running
- User in the `microk8s` group or run the script with root privileges
- Sufficient cluster resources for the ingress controller

## Usage
Make the script executable and run it from the repository folder:

```bash
chmod +x MikroK8SIngress.sh
./MikroK8SIngress.sh
```

Options:
- `--skip-disable` — do not disable the addon before enabling (preserve existing state)
- `--wait <seconds>` — maximum seconds to wait for ingress pods to become healthy (default 60)
- `-h, --help` — show usage

Example with custom wait time:
```bash
./MikroK8SIngress.sh --wait 120
```

## Verification
Check ingress controller pods and service:
```bash
microk8s kubectl -n ingress get pods
microk8s kubectl -n ingress get svc
```

Create an Ingress resource and verify routing:
```bash
microk8s kubectl apply -f examples/my-ingress.yaml
# then test using curl against cluster IP / external ingress
```

## Troubleshooting
- If the script reports `microk8s CLI not found`, ensure MicroK8s is installed and in PATH.
- If pods are CrashLooping or pending:
  - Inspect pod logs:
    ```bash
    microk8s kubectl -n ingress logs <pod-name>
    ```
  - Describe pod for events:
    ```bash
    microk8s kubectl -n ingress describe pod <pod-name>
    ```
- Permission issues: add your user to microk8s group:
  ```bash
  sudo usermod -a -G microk8s $USER && newgrp microk8s
  ```

## Security notes
- Review ingress rules and TLS settings before exposing services externally.
- Do not commit secrets or TLS private keys into version control.

## References
- MicroK8s Ingress Addon: https://microk8s.io/docs/addon-ingress
- Kubernetes Ingress: https://kubernetes.io/docs/concepts/services-networking/ingress/
- NGINX Ingress Controller docs: https://kubernetes.github.io/ingress-nginx/
