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
- To fully disable Rsudo python3 ./create-external-cluster-resources.py --rbd-data-pool-name test-rbd --namespace rook-ceph --cephfs-filesystem-name cephfs --format bashook addon:
  ```bash
  microk8s disable rook-ceph
  ```
## Problems avoiding

In some versions the standard microk8s way of life is not working 
Please follow manually instruction on https://www.rook.io/docs/rook/v1.13/CRDs/Cluster/external-cluster/#prerequisites

Steps:
 1. Run the python script create-external-cluster-resources.py for creating all users and keys. -> Source Cluster
 2. Run the import script. -> Target Cluster (MicroK8S)

### Example on ceph-cluster

````bash
wget https://raw.githubusercontent.com/rook/rook/de8c2d2033f9a46618eb4143039e1d9dbc6ebc39/deploy/examples/create-external-cluster-resources.py
--2025-11-16 11:47:29--  https://raw.githubusercontent.com/rook/rook/de8c2d2033f9a46618eb4143039e1d9dbc6ebc39/deploy/examples/create-external-cluster-resources.py
Resolving raw.githubusercontent.com (raw.githubusercontent.com)... 185.199.108.133, 185.199.110.133, 185.199.111.133, ...
Connecting to raw.githubusercontent.com (raw.githubusercontent.com)|185.199.108.133|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 104667 (102K) [text/plain]
Saving to: ‘create-external-cluster-resources.py’

create-external-cluster-resources.py              100%[==========================================================================================================>] 102,21K  --.-KB/s    in 0,03s   

2025-11-16 11:47:29 (3,72 MB/s) - ‘create-external-cluster-resources.py’ saved [104667/104667]

ansible@micro1:~/ceph$ sudo python3 ./create-external-cluster-resources.py --rbd-data-pool-name test-rbd --namespace rook-ceph --cephfs-filesystem-name cephfs --format bash
export ARGS="[Configurations]
namespace = rook-ceph
rgw-pool-prefix = default
format = bash
cephfs-filesystem-name = cephfs
cephfs-metadata-pool-name = cephfs_metadata
cephfs-data-pool-name = cephfs_data
rbd-data-pool-name = test-rbd
"
export NAMESPACE=rook-ceph
export ROOK_EXTERNAL_FSID=##########
export ROOK_EXTERNAL_USERNAME=client.healthchecker
export ROOK_EXTERNAL_CEPH_MON_DATA=micro4.slainte.at=192.168.0.194:6789
export ROOK_EXTERNAL_USER_SECRET=##########
export ROOK_EXTERNAL_DASHBOARD_LINK=http://192.168.0.194:8080/
export CSI_RBD_NODE_SECRET=##########
export CSI_RBD_NODE_SECRET_NAME=csi-rbd-node
export CSI_RBD_PROVISIONER_SECRET=##########
export CSI_RBD_PROVISIONER_SECRET_NAME=csi-rbd-provisioner
export CEPHFS_POOL_NAME=cephfs_data
export CEPHFS_METADATA_POOL_NAME=cephfs_metadata
export CEPHFS_FS_NAME=cephfs
export CSI_CEPHFS_NODE_SECRET=##########
export CSI_CEPHFS_PROVISIONER_SECRET=##########
export CSI_CEPHFS_NODE_SECRET_NAME=csi-cephfs-node
export CSI_CEPHFS_PROVISIONER_SECRET_NAME=csi-cephfs-provisioner
export MONITORING_ENDPOINT=192.168.0.194
export MONITORING_ENDPOINT_PORT=9283
export RBD_POOL_NAME=test-rbd
export RGW_POOL_PREFIX=default

````

### Example on k8s-cluster

Please consider, that the values are environment dependend as well.

Prepare your environment with


````bash
 git clone https://github.com/rook/rook.git
````

Then execute your script (and adopt the values before). Please check the values.yaml for your helm-commands as well

````bash
ansible@lxd:~/ceph$ ceph_test.sh 
#
#check
#
ansible@k8stest:~/ceph/rook/deploy/charts/rook-ceph-cluster$ kubectl --namespace rook-ceph get cephcluster
NAME        DATADIRHOSTPATH   MONCOUNT   AGE   PHASE       MESSAGE                          HEALTH      EXTERNAL   FSID
rook-ceph   /var/lib/rook     3          42s   Connected   Cluster connected successfully   HEALTH_OK   true       7ca92fa6-c971-4091-8d6d-741175f39e78

ansible@k8stest:~/ceph/rook/deploy/charts/rook-ceph-cluster$ k get all -n rook-ceph
NAME                                                           READY   STATUS    RESTARTS        AGE
pod/ceph-csi-controller-manager-78d4fd465-tpw4s                1/1     Running   2 (2m22s ago)   6m44s
pod/rook-ceph-operator-7fc848bf99-fprph                        1/1     Running   0               6m44s
pod/rook-ceph.cephfs.csi.ceph.com-ctrlplugin-5456dbbd6-z4vxn   5/5     Running   0               3m46s
pod/rook-ceph.cephfs.csi.ceph.com-nodeplugin-vfn69             2/2     Running   0               3m46s
pod/rook-ceph.rbd.csi.ceph.com-ctrlplugin-58d6cb98cb-vbjhx     5/5     Running   0               3m46s
pod/rook-ceph.rbd.csi.ceph.com-nodeplugin-q42j2                2/2     Running   0               3m46s

NAME                                                      DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
daemonset.apps/rook-ceph.cephfs.csi.ceph.com-nodeplugin   1         1         1       1            1           <none>          3m46s
daemonset.apps/rook-ceph.rbd.csi.ceph.com-nodeplugin      1         1         1       1            1           <none>          3m46s

NAME                                                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/ceph-csi-cexport NAMESPACE=rook-ceph
deployment.apps/rook-ceph-operator                         1/1     1            1           6m44s
deployment.apps/rook-ceph.cephfs.csi.ceph.com-ctrlplugin   1/1     1            1           3m46s
deployment.apps/rook-ceph.rbd.csi.ceph.com-ctrlplugin      1/1     1            1           3m46s

NAME                                      #deployment.apps/rook-ceph-operator                         1/1     1            1           6m44s
#deployment.apps/rook-ceph.cephfs.csi.ceph.com-ctrlplugin   1/1     1            1           3m46s
#deployment.apps/rook-ceph.rbd.csi.ceph.com-ctrlplugin      1/1     1            1           3m46s
#
#NAME                                                                 DESIRED   CURRENT   READY   AGE
#replicaset.apps/ceph-csi-controller-manager-78d4fd465                1         1         1       6m44s
#replicaset.apps/rook-ceph-operator-7fc848bf99                        1         1         1       6m44s
#replicaset.apps/rook-ceph.cephfs.csi.ceph.com-ctrlplugin-5456dbbd6   1         1         1       3m46s
#replicaset.apps/rook-ceph.rbd.csi.ceph.com-ctrlplugin-58d6cb98cb     1         1         1       3m46s
#ansible@k8stest:~/ceph/rook/deploy/charts/rook-ceph-cluster$

````

Then proceed with your tests.


## Security notes
- Do not commit `ceph.conf` or keyrings to version control.
- Keep access to Ceph keyrings and admin credentials restricted.
- For production, prefer secure secret management rather than plaintext files.
                           DESIRED   CURRENT   READY   AGE
replicaset.apps/ceph-csi-controller-manager-78d4fd465                1         1         1       6m44s
replicaset.apps/rook-ceph-operator-7fc848bf99                        1         1         1       6m44s
replicaset.apps/rook-ceph.cephfs.csi.ceph.com-ctrlplugin-5456dbbd6   1         1         1       3m46s
replicaset.apps/rook-ceph.rbd.csi.ceph.com-ctrlplugin-58d6cb98cb     1         1         1       3m46s
ansible@k8stest:~/ceph/rook/deploy/charts/rook-ceph-cluster$

````

Then proceed with your tests.


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

