# RookCeph Kubernetes Integration

This directory provides scripts and manifests to deploy, test, and interact with RookCeph storage in a Kubernetes cluster (e.g., MicroK8s).

---

## Project Overview

- **RookCeph.sh**: Automates the installation and configuration of RookCeph on your Kubernetes cluster.
- **test/**: Contains utilities and manifests for validating RookCeph storage with test pods.

---

## Prerequisites

- Kubernetes cluster (e.g., MicroK8s) up and running
- User in the `microk8s` and `sudo` groups (if using MicroK8s)
- `kubectl` installed and configured
- Sufficient permissions to install operators and create resources

---

## Usage

### 1. Install RookCeph

```bash
chmod +x RookCeph.sh
./RookCeph.sh
```

### 2. Deploy Test Pod

```bash
kubectl apply -f test/busybox.yaml
```

### 3. Connect to the Test Pod

```bash
cd test
chmod +x kexec.sh
./kexec.sh
```

---

## Configuration

- Adjust storage class, namespace, or resource names in `busybox.yaml` as needed.
- Edit `namespace` and `podname` variables in `test/kexec.sh` to match your environment.

---

## Testing

- After deploying `busybox.yaml`, verify the pod is running:
  ```bash
  kubectl get pods -n <namespace>
  ```
- Use `kexec.sh` to open a shell in the pod and test storage mounts or connectivity.

---

## Troubleshooting

- If pods are stuck in `Pending`, check RookCeph and Ceph status:
  ```bash
  kubectl -n rook-ceph get pods
  kubectl get pvc,pv
  ```
- For permission errors, ensure your user has the correct group memberships and `kubectl` context.
- Review logs for RookCeph operator and Ceph pods for detailed error messages.

---

## Cleanup

- Remove test resources:
  ```bash
  kubectl delete -f test/busybox.yaml
  ```
- Uninstall RookCeph using the provided script or follow the official documentation.

---

## Security Notes

- Do not use test pods or scripts in production environments.
- Never store sensitive data in test manifests or scripts.
- Review all scripts and YAML before use.

---

## References

- [Rook Documentation](https://rook.io/)
- [Rook Ceph Documentation](https://rook.io/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [MicroK8S Documentation](https://microk8s.io/docs/how-to-ceph)
- [MicroK8S add on Documentation](https://microk8s.io/docs/addon-rook-ceph)
- [Hands on Example](https://datavirke.dk/posts/bare-metal-kubernetes-part-6-persistent-storage-with-rook-ceph/)
