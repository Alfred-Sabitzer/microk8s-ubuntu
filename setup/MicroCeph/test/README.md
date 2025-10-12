# RookCeph Test Utilities

This folder contains scripts and manifests for testing RookCeph storage integration in Kubernetes.

## Files

- `busybox.yaml`: Deploys a BusyBox pod for storage and connectivity tests.
- `kexec.sh`: Connects to a shell inside the BusyBox pod (or any pod matching the name).

## Prerequisites

- Kubernetes cluster with RookCeph installed and running.
- `kubectl` configured and in your PATH.
- The test namespace and pod must exist.

## Usage

1. Deploy the test pod:
    ```bash
    kubectl apply -f busybox.yaml
    ```

2. Connect to the pod:
    ```bash
    ./kexec.sh
    ```

## Configuration

- Edit `namespace` and `podname` variables in `kexec.sh` to match your environment.

## Testing

- Use the shell to verify storage mounts, network connectivity, and other diagnostics.

## Troubleshooting

- If `kexec.sh` reports "No pod matching...", check that the pod is running:
    ```bash
    kubectl get pods -n <namespace>
    ```
- Ensure you have the correct permissions and context set in `kubectl`.

## Cleanup

- Remove the test pod:
    ```bash
    kubectl delete -f busybox.yaml
    ```

## Security Notes

- Do not use test pods or scripts in production environments.
- Review scripts before use to avoid accidental data loss.

## References

- [RookCeph Documentation](https://rook.io/docs/)
- [Kubernetes Exec Documentation](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#exec)

