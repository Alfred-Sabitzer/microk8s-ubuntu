# Rook + Ceph (MicroK8s) — Setup and Verification - CSI Snapshotter

Check Setup

````bash
ansible@k8stest:~$ kubectl get storageclasses.storage.k8s.io 
NAME                 PROVISIONER                     RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
ceph-rbd (default)   rook-ceph.rbd.csi.ceph.com      Delete          Immediate              true                   169d
cephfs               rook-ceph.cephfs.csi.ceph.com   Delete          Immediate              true                   169d
microk8s-hostpath    microk8s.io/hostpath            Delete          WaitForFirstConsumer   false                  169d

ansible@k8stest:~$ kubectl get volumesnapshotclasses.snapshot.storage.k8s.io 
NAME                           DRIVER                          DELETIONPOLICY   AGE
ceph-test-fs-snapshot-class    ://rook-ceph.rbd.csi.ceph.com   Delete           4h2m
ceph-test-rbd-snapshot-class   ://rook-ceph.rbd.csi.ceph.com   Delete           4h2m

````


Deploy demo-Test-sets

````bash
kubectl apply -f https://raw.githubusercontent.com/Alfred-Sabitzer/microk8s-ubuntu/refs/heads/main/setup/RookCeph/test/busybox_rwo.yaml
kubectl apply -f https://raw.githubusercontent.com/Alfred-Sabitzer/microk8s-ubuntu/refs/heads/main/setup/RookCeph/test/busybox_rwx.yaml
````

Create snapshots

````bash
kubectl apply -f ./rookrbd.yaml
kubectl apply -f ./rookrwx.yaml
````

Deploy the snapshot-controller:

````bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/master/deploy/kubernetes/snapshot-controller/rbac-snapshot-controller.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/master/deploy/kubernetes/snapshot-controller/setup-snapshot-controller.yaml
````

Verify the installation:

````bash
kubectl api-resources | grep volumesnapshot
````

(You should now see volumesnapshots, volumesnapshotcontents, and volumesnapshotclasses).

Important RequirementsCSI Driver: VolumeSnapshot only works with CSI-backed storage. The default MicroK8s hostpath addon does not support snapshots out of the box. You will need to use a CSI driver (like Ceph-CSI, Longhorn, or the OpenEBS Hostpath CSI driver) that provides snapshot capabilities.VolumeSnapshotClass: You must create a specific VolumeSnapshotClass object that references your CSI driver so Kubernetes knows how to execute the snapshot.


See: https://github.com/rook/rook/issues/6819 
https://oneuptime.com/blog/post/2026-03-31-rook-csi-snapshotter/view
