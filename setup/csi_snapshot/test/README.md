# Rook + Ceph (MicroK8s) — Setup and Verification - CSI Snapshotter

Check Setup

````bash
ansible@k8stest:~$ kubectl get storageclasses.storage.k8s.io 
NAME                 PROVISIONER                     RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
ceph-rbd (default)   rook-ceph.rbd.csi.ceph.com      Delete          Immediate              true                   169d
cephfs               rook-ceph.cephfs.csi.ceph.com   Delete          Immediate              true                   169d
microk8s-hostpath    microk8s.io/hostpath            Delete          WaitForFirstConsumer   false                  169d

ansible@k8stest:~$ kubectl get volumesnapshotclasses.snapshot.storage.k8s.io 
NAME                           DRIVER                             DELETIONPOLICY   AGE
ceph-test-fs-snapshot-class    ://rook-ceph.cephfs.csi.ceph.com   Delete           3m29s
ceph-test-rbd-snapshot-class   ://rook-ceph.rbd.csi.ceph.com      Delete           3m29s
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

check snapshots

````bash
kubectl get volumesnapshots.snapshot.storage.k8s.io -n rook-ceph rookrbd-snapshot
kubectl get volumesnapshots.snapshot.storage.k8s.io -n rook-ceph rookrwx-snapshot


kubectl describe volumesnapshot -n rook-ceph rookrbd-snapshot
kubectl describe volumesnapshot -n rook-ceph rookrwx-snapshot

````

See: https://github.com/rook/rook/issues/6819 
https://oneuptime.com/blog/post/2026-03-31-rook-csi-snapshotter/view
