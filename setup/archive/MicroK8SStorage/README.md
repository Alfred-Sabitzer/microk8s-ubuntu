# MicroK8SStorage

Configuration of ClusterStrorage

Please consider https://microk8s.io/docs/addons, https://microk8s.io/docs/addon-rook-ceph, https://microk8s.io/docs/addon-nfs and https://microk8s.io/docs/addon-mayastor.

We go for https://microk8s.io/docs/addon-openebs

```` bashe
slainte@k8s:~/alfred/setup$ k get storageclasses.storage.k8s.io
NAME                                 PROVISIONER            RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
openebs-device                       openebs.io/local       Delete          WaitForFirstConsumer   false                  13m
microk8s-hostpath                    microk8s.io/hostpath   Delete          WaitForFirstConsumer   false                  89s
openebs-jiva-csi-default (default)   jiva.csi.openebs.io    Delete          Immediate              true                   13m
openebs-hostpath                     openebs.io/local       Delete          WaitForFirstConsumer   false                  13m
slainte@k8s:~/alfred/setup$ 
````

Default is openebs-jiva-csi-default. See https://microk8s.io/docs/addon-openebs 

## On multi-node MicroK8s

If you are planning to use OpenEBS with multi nodes, you can use the openebs-jiva-csi-default StorageClass.
For example:

````yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: jiva-volume-claim
spec:
  storageClassName: openebs-jiva-csi-default
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5G
````

# CLuster Storage

Cluster-Storage wird gebraucht, wenn man eine RWMANX-PVC machen muß (ist in manchmal notwendig).
Longhorn funktioniert derzeit nicht in Kubernetes V25 (wegen PodPolicy).

-> Dies wird automatisch in /MicroK8SNFS.sh gemacht.

```bash
Installing NFS Server Provisioner - Helm Chart 1.4.0

Node Name not defined. NFS Server Provisioner will be deployed on random Microk8s Node.

If you want to use a dedicated (large disk space) Node as NFS Server, disable the Addon and start over: microk8s enable nfs -n NODE_NAME
Lookup Microk8s Node name as: kubectl get node -o yaml | grep 'kubernetes.io/hostname'

Preparing PV for NFS Server Provisioner

persistentvolume/data-nfs-server-provisioner-0 created
"nfs-ganesha-server-and-external-provisioner" has been added to your repositories
Release "nfs-server-provisioner" does not exist. Installing it now.
NAME: nfs-server-provisioner
LAST DEPLOYED: Wed Jan  4 15:53:40 2023
NAMESPACE: nfs-server-provisioner
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
The NFS Provisioner service has now been installed.

A storage class named 'nfs' has now been created
and is available to provision dynamic volumes.

You can use this storageclass by creating a `PersistentVolumeClaim` with the
correct storageClassName attribute. For example:

    ---
    kind: PersistentVolumeClaim
    apiVersion: v1
    metadata:
      name: test-dynamic-volume-claim
    spec:
      storageClassName: "nfs"
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 100Mi

NFS Server Provisioner is installed
```

