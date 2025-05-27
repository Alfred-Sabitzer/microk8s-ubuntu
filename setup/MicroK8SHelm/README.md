# MicroK8SHelm

This script enables the Helm 3 addon for MicroK8s and sets up the `helm` command alias.

## Prerequisites

- [MicroK8s](https://microk8s.io/) installed and running
- User in the `microk8s` group or root privileges
- `sudo` privileges for setting the `helm` alias

## Usage

```bash
chmod +x MicroK8SHelm.sh
./MicroK8SHelm.sh
```

The script will:
- Disable and re-enable the `helm3` addon to ensure a clean state
- Set up the `helm` command alias for convenience

## Notes

- If you encounter permission errors, try running the script with `sudo`.
- For more information on Helm, see [https://helm.sh/](https://helm.sh/).

## Troubleshooting

- Ensure your user is in the `microk8s` group:  
  `sudo usermod -a -G microk8s $USER && newgrp microk8s`
- Check MicroK8s status:  
  `microk8s status`
- If the `helm` alias is not set, run:
  ```bash
  sudo snap unalias helm || true
  sudo snap alias microk8s.helm3 helm
  ```
