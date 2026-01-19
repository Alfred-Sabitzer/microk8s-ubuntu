# MicroK8SCommunity

This script enables the sudo microk8s community repository and essential addons: `dns`, `rbac`, and legacy `hostpath-storage`.

## Prerequisites

- [MicroK8s](https://microk8s.io/) installed on your system
- Sudo/root privileges (if required for sudo microk8s commands)

## Usage

```bash
chmod +x MicroK8SCommunity.sh
./MicroK8SCommunity.sh
```

The script will:
- Check if sudo microk8s is installed
- Enable the required addons one by one (if not already enabled)
- Wait for sudo microk8s to be ready after each step

## Notes

- Do **not** enable or disable multiple addons in a single command; this script follows best practices by enabling them one at a time.
- If you encounter permission errors, try running the script with `sudo`.

## Troubleshooting

- Ensure your user is in the `microk8s` group:  
  `sudo usermod -a -G sudo microk8s $USER && newgrp microk8s`
- Check sudo microk8s status:  
  `sudo microk8s status`