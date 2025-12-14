# RookCeph Test Utilities (observability namespace)

Purpose
- Test manifests and helper scripts to validate Ceph RBD (RWO) and CephFS (RWX) mounts in the observability namespace.

Files
- busybox_rwo.yaml — PVC (RBD) + BusyBox Deployment (ReadWriteOnce) using PVC `observability-rbd-pvc`.
- busybox_rwx.yaml — PVC (CephFS) + BusyBox Deployment (ReadWriteMany) using PVC `observability-cephfs-pvc`.
- kexec_rwo.sh — exec helper to connect to the RWO test pod (defaults: namespace=observability, label=app=observability-rbd).
- kexec_rwx.sh — exec helper to connect to the RWX test pod (defaults: namespace=observability, label=app=observability-cephfs).

Quick usage
1. Inspect and adjust StorageClass names in the YAMLs (ceph-rbd / rook-cephfs).
2. Apply manifests:
   microk8s kubectl apply -f busybox_rwo.yaml
   microk8s kubectl apply -f busybox_rwx.yaml
3. Wait for pods to be Ready and exec:
   ./kexec_rwo.sh
   ./kexec_rwx.sh
   Or pass namespace/label as args:
   ./kexec_rwo.sh myns "app=mylabel"

Cleanup
- Delete resources:
  microk8s kubectl delete -f busybox_rwo.yaml
  microk8s kubectl delete -f busybox_rwx.yaml
- Delete PVCs only when data is no longer needed:
  microk8s kubectl -n observability delete pvc observability-rbd-pvc observability-cephfs-pvc

Notes
- These manifests are targeted at the `observability` namespace and use names prefixed with `observability-` for clarity.
- Adjust storageClassName to match your cluster.
- These are testing examples — do not use hostPath/static PVs in production.

