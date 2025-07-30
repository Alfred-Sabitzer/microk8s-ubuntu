# MicroK8S NFS Storage

This setup enables NFS storage for MicroK8s clusters, allowing dynamic provisioning of persistent volumes using NFS.

## Prerequisites

- [MicroK8s](https://microk8s.io/) installed and running
- User in the `microk8s` group or root privileges
- `helm` installed (for provisioning with Helm charts)
- NFS server installed and configured (see below)

## NFS Server Setup

Install and configure the NFS server:

```bash
sudo apt install nfs-kernel-server
sudo mkdir -p /mnt/nfs_share
sudo chown -R nobody:nogroup /mnt/nfs_share/
echo "/mnt/nfs_share 10.0.0.0/24(rw,insecure,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports
echo "/mnt/nfs_share 127.0.0.1(rw,insecure,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports
sudo exportfs -a
sudo systemctl restart nfs-kernel-server
sudo ufw allow from 10.0.0.0/24 to any port nfs
sudo ufw allow from 127.0.0.1 to any port nfs
```

> **Note:** The `no_root_squash` option is necessary for Kubernetes dynamic provisioning but reduces security. Use with caution.

## NFS Client Setup

Install the NFS client utilities:

```bash
sudo apt install nfs-common
```

## Deploy NFS Provisioner

Add the Helm repo and install the provisioner:

```bash
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
kubectl create ns nfsstorage
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --set nfs.server=127.0.0.1 --set nfs.path=/mnt/nfs_share -n nfsstorage
```

## Testing

Create a PersistentVolumeClaim:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-claim
  namespace: default
spec:
  storageClassName: nfs-client
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Mi
```

Apply and verify:

```bash
kubectl apply -f test-claim.yaml
kubectl get pvc -n default
ls /mnt/nfs_share/
```

## Cleanup

To delete the test PVC:

```bash
kubectl delete pvc -n default test-claim
```

## References

- [Kubernetes NFS Provisioner](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner)
- [Kubernetes Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
