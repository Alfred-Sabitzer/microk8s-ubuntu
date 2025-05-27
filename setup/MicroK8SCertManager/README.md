# MicroK8SCertManager

This script enables the MicroK8s cert-manager addon and applies a sample ClusterIssuer for Let's Encrypt.

## Prerequisites

- [MicroK8s](https://microk8s.io/) installed and running
- User in the `microk8s` group or root privileges
- `cert-manager.yaml` present in the same directory as the script

## Usage

```bash
chmod +x MicroK8SCertManager.sh
./MicroK8SCertManager.sh
```

The script will:
- Disable and re-enable the cert-manager addon to ensure a clean state
- Apply the `cert-manager.yaml` configuration (e.g., ClusterIssuer)
- Wait for MicroK8s to be ready after each step

## Notes

- Edit `cert-manager.yaml` to use your own email address and adjust solver settings as needed.
- If you encounter permission errors, try running the script with `sudo`.

## Troubleshooting

- Ensure your user is in the `microk8s` group:  
  `sudo usermod -a -G microk8s $USER && newgrp microk8s`
- Check MicroK8s status:  
  `microk8s status`
- For more info, see [MicroK8s cert-manager docs](https://microk8s.io/docs/addon-cert-manager)

