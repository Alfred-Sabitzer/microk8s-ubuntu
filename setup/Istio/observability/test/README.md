# Service Monitor Test Utilities

This folder contains scripts and manifests for testing Egress Connections

## Files

- `ubuntu.yaml`: Deploys a BusyBox pod for storage and connectivity tests.
- `kexec.sh`: Connects to a shell inside the BusyBox pod (or any pod matching the name).

## Prerequisites

- Kubernetes cluster with RookCeph installed and running.
- `kubectl` configured and in your PATH.
- The test namespace and pod must exist.

## Usage

1. Deploy the test pod:
    ```bash
    kubectl apply -f ubuntu.yaml
    ```

2. Connect to the pod:
    ```bash
    ./kexec.sh
    ```

## Configuration

- Edit `namespace` and `podname` variables in `kexec.sh` to match your environment.

## Testing

- Use the shell to verify network connectivity and other diagnostics.

## Troubleshooting

- If `kexec.sh` reports "No pod matching...", check that the pod is running:
    ```bash
    kubectl get pods -n <namespace>
    ```
- Ensure you have the correct permissions and context set in `kubectl`.

## Cleanup

- Remove the test pod:
    ```bash
    kubectl delete -f ubuntu.yaml
    ```

## Security Notes

- Do not use test pods or scripts in production environments.
- Review scripts before use to avoid accidental data loss.

## References

- [Istio Gateway / VirtualService:](https://istio.io/latest/docs/reference/config/networking/gateway/)
- [Istio ServiceEntry:](https://istio.io/latest/docs/reference/config/networking/service-entry/)
- [Istio Sidecar (egress control):](https://istio.io/latest/docs/reference/config/networking/sidecar/)
- [Istio and Metallb](https://support.tools/install-metallb-istio-ingress-mtls-kubernetes/)
- [Istio get client source ip](https://docs.daocloud.io/en/network/modules/metallb/source_ip/)
- [Istio security examples ](https://istio.io/latest/docs/ops/configuration/security/security-policy-examples/)
- [Istio security best practices ](https://istio.io/latest/docs/ops/best-practices/security/)
- [Istio egress gateway pattern: ](https://istio.io/latest/docs/tasks/traffic-management/egress/egress-gateway/)
- [ServiceEntry: ](https://istio.io/latest/docs/reference/config/networking/service-entry/)
- [VirtualService: ](https://istio.io/latest/docs/reference/config/networking/virtual-service/)
- [Kubernetes Exec Documentation](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#exec)
