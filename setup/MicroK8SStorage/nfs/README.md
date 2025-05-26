**Es gibt mittlerweile auch die Möglichkeit den NFS-Server der Community zu benutzen!**

## NFS-Server

Es muß der NFS-Server-Teil installiert werden. Die NFS-Shares sind dann auf /mnt/nfs_share

```bash
sudo apt install nfs-kernel-server
sudo mkdir -p /mnt/nfs_share
sudo chown -R nobody:nogroup /mnt/nfs_share/
sudo su -l
root@v22022112011208453:~# echo "/mnt/nfs_share 10.0.0.0/24(rw,insecure,sync,no_subtree_check,no_root_squash)" >> /etc/exports
root@v22022112011208453:~# echo "/mnt/nfs_share 127.0.0.1(rw,insecure,sync,no_subtree_check,no_root_squash)" >> /etc/exports
root@v22022112011208453:~# exit


cat /etc/exports

# /etc/exports: the access control list for filesystems which may be exported
#		to NFS clients.  See exports(5).
#
# Example for NFSv2 and NFSv3:
# /srv/homes       hostname1(rw,sync,no_subtree_check) hostname2(ro,sync,no_subtree_check)
#
# Example for NFSv4:
# /srv/nfs4        gss/krb5i(rw,sync,fsid=0,crossmnt,no_subtree_check)
# /srv/nfs4/homes  gss/krb5i(rw,sync,no_subtree_check)
#
/mnt/nfs_share 10.0.0.0/24(rw,sync,no_subtree_check)
/mnt/nfs_share 127.0.0.1(rw,sync,no_subtree_check)


sudo exportfs -a
sudo systemctl restart nfs-kernel-server
sudo ufw allow from 10.0.2.15/24 to any port nfs
sudo ufw allow from 127.0.0.1 to any port nfs


sudo ufw status
```
(rw,insecure,sync,no_subtree_check,no_root_squash) ist notwendig um zu "root_sqashing" zu verhindern.
Siehe auch https://www.thegeekdiary.com/basic-nfs-security-nfs-no_root_squash-and-suid/

## NFS-Client

Wir brauchen auch noch die Client-Software.

```bash
sudo apt install nfs-common
```

## NFS-FileProvisioner für K8S

Jetzt brauchen wir noch einen File-Provisioner für Kubernetes.
Wir folgen dieser Anleitung.

https://www.unixarena.com/2022/10/kubernetes-setup-dynamic-nfs-storage-provisioning-helm.html/

```bash
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
kubectl create ns nfsstorage # Das machen wir im Repo /namespaces
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner  --set nfs.server=127.0.0.1 --set nfs.path=/mnt/nfs_share -n nfsstorage
```

Danach prüfen wir die Installation

```bash
kubectl get all -n nfsstorage
NAME                                                  READY   STATUS    RESTARTS   AGE
pod/nfs-subdir-external-provisioner-64489bf7d-jm4fg   2/2     Running   0          20s

NAME                                              READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nfs-subdir-external-provisioner   1/1     1            1           20s

NAME                                                        DESIRED   CURRENT   READY   AGE
replicaset.apps/nfs-subdir-external-provisioner-64489bf7d   1         1         1       20s


kubectl get storageclass 
NAME                         PROVISIONER                                     RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
openebs-device               openebs.io/local                                Delete          WaitForFirstConsumer   false                  3d22h
microk8s-hostpath            microk8s.io/hostpath                            Delete          WaitForFirstConsumer   false                  12d
openebs-jiva-csi-default     jiva.csi.openebs.io                             Delete          Immediate              true                   3d22h
openebs-hostpath (default)   openebs.io/local                                Delete          WaitForFirstConsumer   false                  3d22h
nfs-client                   cluster.local/nfs-subdir-external-provisioner   Delete          Immediate              true                   115s

kubectl get storageclasses.storage.k8s.io nfs-client -o yaml
allowVolumeExpansion: true
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    meta.helm.sh/release-name: nfs-subdir-external-provisioner
    meta.helm.sh/release-namespace: nfsstorage
  creationTimestamp: "2022-12-10T20:47:34Z"
  labels:
    app: nfs-subdir-external-provisioner
    app.kubernetes.io/managed-by: Helm
    chart: nfs-subdir-external-provisioner-4.0.17
    heritage: Helm
    release: nfs-subdir-external-provisioner
  name: nfs-client
  resourceVersion: "2809351"
  uid: 2dfeb5d9-8a77-45e1-bcc9-178e8f07eed8
parameters:
  archiveOnDelete: "true"
provisioner: cluster.local/nfs-subdir-external-provisioner
reclaimPolicy: Delete
volumeBindingMode: Immediate
```
Um das ganz zu testen, erzeugen wir eine pvc

```bash
kind: PersistentVolumnfseClaim
apiVersion: v1
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
Dann spielen wir das ein, und überprüfen, was rauskommt.

```bash
k get pvc -n default
NAME         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
test-claim   Bound    pvc-14803626-2ed6-426a-9937-74803f462508   1Mi        RWX            nfs-client     17s
```
Mal sehen was am NFS-Shar ist.

```bash
ls /mnt/nfs_share/ -lisa
total 12
1069491 4 drwxrwxrwx 3 nobody nogroup 4096 Dez 10 21:54 .
18 4 drwxr-xr-x 3 root   root    4096 Dez 10 21:25 ..
1069492 4 drwxrwxrwx 2 nobody nogroup 4096 Dez 10 21:54 default-test-claim-pvc-14803626-2ed6-426a-9937-74803f462508
```
Und was passiert beim Löschen?

```bash
kubectl delete pvc -n default test-claim
persistentvolumeclaim "test-claim" deleted

slainte@v22022112011208453:~$ ls /mnt/nfs_share/ -lisa
total 12
1069491 4 drwxrwxrwx 3 nobody nogroup 4096 Dez 10 21:56 .
18 4 drwxr-xr-x 3 root   root    4096 Dez 10 21:25 ..
1069492 4 drwxrwxrwx 2 nobody nogroup 4096 Dez 10 21:54 archived-default-test-claim-pvc-14803626-2ed6-426a-9937-74803f462508
```
Die PVC wird nach "Archived ..." umbenannt.
Das Konzept scheint sypmathisch zu sein.
