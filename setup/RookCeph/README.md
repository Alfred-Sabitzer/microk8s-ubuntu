# Rook + Ceph (MicroK8s) — Setup and Verification

This folder contains scripts and test manifests to integrate Rook with a Ceph cluster on MicroK8s. It assumes a Ceph cluster is available (either MicroCeph/MicroCloud-installed or external) and shows how to enable the rook-ceph addon, optionally connect to an external Ceph, and verify storage classes.

## Project overview
- Enable and validate the Rook operator on MicroK8s.
- Optionally connect Rook to an existing external Ceph cluster.
- Verify and set Ceph RBD as default StorageClass for the cluster.
- Provide simple test utilities under `test/` (busybox pod and exec helper).

## Prerequisites
- MicroK8s installed and running
- User in `microk8s` group or use `sudo` for microk8s commands
- `microk8s` command available in PATH
- If connecting external Ceph: valid `ceph.conf` and `ceph.keyring` accessible on the host

## Usage
1. Make script executable and run:
   ```bash
   chmod +x RookCeph.sh
   sudo ./RookCeph.sh
   ```

2. If you have an external Ceph, place `ceph.conf` and `ceph.keyring` at the paths configured in the script (or edit the script to point to your files) before running.

3. Verify Rook and Ceph:
   ```bash
   microk8s kubectl -n rook-ceph get pods
   microk8s kubectl get storageclasses
   ```

## Test utilities
- `test/busybox.yaml` — simple pod to verify PVC provisioning.
- `test/kexec.sh` — connect to a pod shell (edit namespace/podname variables as needed).
- Use:
   ```bash
   microk8s kubectl apply -f test/busybox.yaml
   cd test
   chmod +x kexec.sh
   ./kexec.sh
   ```

## Testing & Validation
- Check Rook operator:
  ```bash
  microk8s kubectl -n rook-ceph get pods -l app=rook-ceph-operator
  ```
- Confirm Ceph cluster (if external connection used):
  ```bash
  microk8s kubectl -n rook-ceph-external get cephcluster
  ```
- Validate PV/PVC provisioning:
  ```bash
  microk8s kubectl get pvc,pv -A
  ```

## Troubleshooting
- If pods are pending, check events and describe the pod:
  ```bash
  microk8s kubectl -n rook-ceph describe pod <pod-name>
  microk8s kubectl -n rook-ceph get events --sort-by='.lastTimestamp'
  ```
- Check operator logs:
  ```bash
  microk8s kubectl -n rook-ceph logs <operator-pod-name>
  ```

## Cleanup
- Remove test resources:
  ```bash
  microk8s kubectl delete -f test/busybox.yaml
  ```
- To fully disable Rook addon:
  ```bash
  microk8s disable rook-ceph
  ```

## Security notes
- Do not commit `ceph.conf` or keyrings to version control.
- Keep access to Ceph keyrings and admin credentials restricted.
- For production, prefer secure secret management rather than plaintext files.

## References
- https://microk8s.io/docs/addon-rook-ceph
- https://rook.io/docs/
- https://docs.ceph.com/
- https://canonical-microceph.readthedocs-hosted.com/en/latest/
- https://discuss.kubernetes.io/t/microk8s-microceph-cephfs-ubuntu-22/29022
- https://github.com/canonical/microk8s/issues/4362
- https://www.dbi-services.com/blog/rook-ceph-tips-and-tricks-for-storage-using-cephfs/
- https://web-docs.gsi.de/~vpenso/notes/posts/kubernetes/rook.html
- https://gist.github.com/morrismusumi/16d926b3ec86da1088d00b7f9076f3ed
- https://docs.ceph.com/en/nautilus/dev/kubernetes/
- https://kifarunix.com/configuring-shared-filesystem-for-kubernetes-on-rook-ceph-storage/
- https://www.sysdig.com/blog/monitoring-ceph-prometheus
- https://rook.io/docs/rook/latest/Storage-Configuration/Monitoring/ceph-monitoring/#dashboard-config

<!-- end of README -->

