# MicroK8SMetalLB

This script enables the MetalLB addon for MicroK8s and applies a sample LoadBalancer service for ingress.

## Prerequisites

- [MicroK8s](https://microk8s.io/) installed and running
- User in the `microk8s` group or root privileges
- `MetalLB_Ingress.yaml` present in the same directory as the script

## Usage

```bash
chmod +x MicroK8SMetalLB.sh
./MicroK8SMetalLB.sh
```

The script will:
- Disable and re-enable the MetalLB addon to ensure a clean state
- Enable MetalLB with the IP range `192.168.178.201-192.168.178.210`
- Apply the `MetalLB_Ingress.yaml` configuration for ingress

## Notes

- Edit the IP range in the script to match your network.
- Edit `MetalLB_Ingress.yaml` as needed for your ingress controller.
- If you encounter permission errors, try running the script with `sudo`.

## Troubleshooting

- Ensure your user is in the `microk8s` group:  
  `sudo usermod -a -G microk8s $USER && newgrp microk8s`
- Check MicroK8s status:  
  `microk8s status`
- For more info, see [MicroK8s MetalLB docs](https://microk8s.io/docs/addon-metallb)
