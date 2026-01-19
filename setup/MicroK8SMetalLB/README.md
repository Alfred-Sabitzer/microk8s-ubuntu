# MicroK8SMetalLB

Enable MetalLB on sudo microk8s and apply a sample LoadBalancer manifest.

## Project overview
This script enables MetalLB (Layer2/ARP mode) in a bare-metal sudo microk8s cluster and applies a sample LoadBalancer manifest to demonstrate ingress/service exposure using MetalLB-assigned IPs.

## Prerequisites
- sudo microk8s installed and running
- User in the `microk8s` group or run script with root privileges
- A free IP range on your LAN to assign to MetalLB (no DHCP conflicts)
- `MetalLB_Ingress.yaml` present in the same directory (or provide a manifest path)

## Usage
Make the script executable and run it from the folder containing `MetalLB_Ingress.yaml` (or pass a path):

```bash
chmod +x MicroK8SMetalLB.sh
export IP_RANGE="192.168.178.200-192.168.178.210"
export METALLB_YAML="/path/to/MetalLB_Ingress.yaml"
./MicroK8SMetalLB.sh
# or specify custom range/manifest:
./MicroK8SMetalLB.sh --ip-range 192.168.178.200-192.168.178.210 --yaml ./MetalLB_Ingress.yaml
```

The script will:
- Disable and re-enable the MetalLB addon to ensure a clean state
- Enable MetalLB with the IP range `192.168.178.201-192.168.178.210`
- Apply the `MetalLB_Ingress.yaml` configuration for ingress


## Notes

- Edit the IP range in the script to match your network.
- Edit `MetalLB_Ingress.yaml` as needed for your ingress controller.
- If you encounter permission errors, try running the script with `sudo`.

## Security notes
MetalLB assigns real IP addresses on your LAN — ensure IPs are reserved and monitored.
Do not commit manifests with credentials or secrets to public repositories.

## References
sudo microk8s MetalLB docs: https://microk8s.io/docs/addon-metallb
MetalLB upstream: https://metallb.universe.tf/

## Troubleshooting

- Ensure your user is in the `microk8s` group:  
  `sudo usermod -a -G sudo microk8s $USER && newgrp microk8s`
- Check sudo microk8s status:  
  `sudo microk8s status`
- Check MetalLB pods and config:  
  `sudo microk8s kubectl -n metallb-system get pods`  
  `sudo microk8s kubectl -n metallb-system get configmap`
- Check services to verify MetalLB assignment:  
  `sudo microk8s kubectl get svc -A -o wide`
- For more info, see [sudo microk8s MetalLB docs](https://microk8s.io/docs/addon-metallb)
