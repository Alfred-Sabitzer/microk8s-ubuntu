# RookCeph

https://microk8s.io/docs/addon-rook-ceph
https://github.com/rook/rook
https://rook.io/docs/rook/latest-release/Getting-Started/intro/
https://rook.io/docs/rook/latest-release/Getting-Started/quickstart/#deploy-the-rook-operator
https://microk8s.io/docs/how-to-ceph
https://docs.ceph.com/en/reef/
https://canonical-microceph.readthedocs-hosted.com/en/latest/tutorial/get-started/
https://www.howtoforge.de/anleitung/wie-man-einen-ceph-storage-cluster-unter-ubuntu-1604-installiert/
https://www.digitalocean.com/community/tutorials/how-to-set-up-a-ceph-cluster-within-kubernetes-using-rook
https://ubuntu.com/ceph/install
https://www.thomas-krenn.com/de/wiki/Ceph




```bash
$ curl http://192.168.178.200:8081
<?xml version="1.0" encoding="UTF-8"?><ListAllMyBucketsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Owner><ID>anonymous</ID></Owner><Buckets></Buckets></ListAllMyBucketsResult>alfred@k8s:~$ 

```


# Find out where are my disks

## check my pv's


```bash
kubectl get pv pvc-ddf23ac9-4474-4f19-8be0-1831b6327154 -o yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  annotations:
    pv.kubernetes.io/provisioned-by: rook-ceph.rbd.csi.ceph.com
    volume.kubernetes.io/provisioner-deletion-secret-name: rook-csi-rbd-provisioner
    volume.kubernetes.io/provisioner-deletion-secret-namespace: rook-ceph-external
  creationTimestamp: "2025-05-31T17:08:27Z"
  finalizers:
  - kubernetes.io/pv-protection
  name: pvc-ddf23ac9-4474-4f19-8be0-1831b6327154
  resourceVersion: "11891"
  uid: cc5deaac-e5bc-4f95-8da9-fc9f2a414d27
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 1Mi
  claimRef:
    apiVersion: v1
    kind: PersistentVolumeClaim
    name: rook
    namespace: default
    resourceVersion: "11882"
    uid: ddf23ac9-4474-4f19-8be0-1831b6327154
  csi:
    controllerExpandSecretRef:
      name: rook-csi-rbd-provisioner
      namespace: rook-ceph-external
    driver: rook-ceph.rbd.csi.ceph.com
    fsType: ext4
    nodeStageSecretRef:
      name: rook-csi-rbd-node
      namespace: rook-ceph-external
    volumeAttributes:
      clusterID: rook-ceph-external
      imageFeatures: layering
      imageFormat: "2"
      imageName: csi-vol-817ac001-d510-4b7d-90d9-fccbe70d3fd6
      journalPool: microk8s-rbd0
      pool: microk8s-rbd0
      storage.kubernetes.io/csiProvisionerIdentity: 1748710135840-8081-rook-ceph.rbd.csi.ceph.com
    volumeHandle: 0001-0012-rook-ceph-external-0000000000000002-817ac001-d510-4b7d-90d9-fccbe70d3fd6
  persistentVolumeReclaimPolicy: Delete
  storageClassName: ceph-rbd
  volumeMode: Filesystem
status:
  lastPhaseTransitionTime: "2025-05-31T17:08:27Z"
  phase: Bound

```

## check block-devices

At this time the pod is up and running.
We will Read the content direct from the running pod (and its mounted disk) and direct the rook block-device


```bash
lsblk | grep -v loop
NAME                      MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
sda                         8:0    0    50G  0 disk 
├─sda1                      8:1    0     1M  0 part 
├─sda2                      8:2    0     2G  0 part /boot
└─sda3                      8:3    0    48G  0 part 
  └─ubuntu--vg-ubuntu--lv 252:0    0    48G  0 lvm  /
sr0                        11:0    1    51M  0 rom  
rbd0                      251:0    0     1M  0 disk /var/snap/microk8s/common/var/lib/kubelet/pods/b1506132-87e2-4a97-aca9-b54ed1c4f045/volumes/kubernetes.io~csi/pvc-ddf23ac9-4474-4f19-8be0-1831b6327154/mount
                                                    /var/snap/microk8s/common/var/lib/kubelet/plugins/kubernetes.io/csi/rook-ceph.rbd.csi.ceph.com/2fc02a2e9a285dee8f8cb45699ffa68e95e112f5c04ff55fd79588d095a3a00d/globalmount/0001-0012-rook-ceph-external-0000000000000002-817ac001-d510-4b7d-90d9-fccbe70d3fd6

sudo cat /var/snap/microk8s/common/var/lib/kubelet/pods/b1506132-87e2-4a97-aca9-b54ed1c4f045/volumes/kubernetes.io~csi/pvc-ddf23ac9-4474-4f19-8be0-1831b6327154/mount/hallo.txt
Hallo

sudo cat /var/snap/microk8s/common/var/lib/kubelet/plugins/kubernetes.io/csi/rook-ceph.rbd.csi.ceph.com/2fc02a2e9a285dee8f8cb45699ffa68e95e112f5c04ff55fd79588d095a3a00d/globalmount/0001-0012-rook-ceph-external-0000000000000002-817ac001-d510-4b7d-90d9-fccbe70d3fd6/hallo.txt
Hallo

```

Now the pod is stopped. We will retry.


```bash
lsblk | grep -v loop
NAME                      MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
sda                         8:0    0    50G  0 disk 
├─sda1                      8:1    0     1M  0 part 
├─sda2                      8:2    0     2G  0 part /boot
└─sda3                      8:3    0    48G  0 part 
  └─ubuntu--vg-ubuntu--lv 252:0    0    48G  0 lvm  /
sr0                        11:0    1    51M  0 rom  
rbd0                      251:0    0     1M  0 disk /var/snap/microk8s/common/var/lib/kubelet/plugins/kubernetes.io/csi/rook-ceph.rbd.csi.ceph.com/2fc02a2e9a285dee8f8cb45699ffa68e95e112f5c04ff55fd79588d095a3a00d/globalmount/0001-0012-rook-ceph-external-0000000000000002-817ac001-d510-4b7d-90d9-fccbe70d3fd6


sudo cat /var/snap/microk8s/common/var/lib/kubelet/plugins/kubernetes.io/csi/rook-ceph.rbd.csi.ceph.com/2fc02a2e9a285dee8f8cb45699ffa68e95e112f5c04ff55fd79588d095a3a00d/globalmount/0001-0012-rook-ceph-external-0000000000000002-817ac001-d510-4b7d-90d9-fccbe70d3fd6/hallo.txt
Hallo

```

Contentt is still readable.


## Luks encrypted

Content is luks-encrypted. This is good.
Luks-Passwword can not be revese engineered from microceph (see https://forum.proxmox.com/threads/ceph-luks-password.94868/ and https://canonical-microceph.readthedocs-hosted.com/_/downloads/en/reef-stable/pdf/)

**Excerpt:**

* Also note that the encryption key will be stored on the Ceph monitors as part of the Ceph key/value store
* MicroCeph doesn't store the password directly:
* MicroCeph stores the encryption key, generated from the password, in the Ceph configuration, not the password itself. 
* No password retrieval tool:
* * There is no built-in tool in MicroCeph to directly retrieve or recover the password. 


See as well https://documentation.ubuntu.com/microcloud/latest/microceph/explanation/security/full-disk-encryption/ 


```bash

sudo cryptsetup luksDump /dev/sdia 
LUKS header information
Version:       	2
Epoch:         	3
Metadata area: 	16384 [bytes]
Keyslots area: 	16744448 [bytes]
UUID:          	c523bbee-3db4-4241-ab6d-b678d88f9c98
Label:         	(no label)
Subsystem:     	(no subsystem)
Flags:       	(no flags)

Data segments:
  0: crypt
	offset: 16777216 [bytes]
	length: (whole device)
	cipher: aes-xts-plain64
	sector: 512 [bytes]

Keyslots:
  0: luks2
	Key:        512 bits
	Priority:   normal
	Cipher:     aes-xts-plain64
	Cipher key: 512 bits
	PBKDF:      argon2id
	Time cost:  5
	Memory:     1048576
	Threads:    4
	Salt:       3e 0d 6c 80 c1 17 06 e4 79 b8 ec ea 6c bf 7f e6 
	            3a f0 f8 1e d9 7d b6 f1 cb 9c 4d dc ff 51 8f 80 
	AF stripes: 4000
	AF hash:    sha256
	Area offset:32768 [bytes]
	Area length:258048 [bytes]
	Digest ID:  0
Tokens:
Digests:
  0: pbkdf2
	Hash:       sha256
	Iterations: 96518
	Salt:       45 3c 38 0f 3e ab ca 01 49 bf 03 bb 19 db 94 ed 
	            45 1b a9 68 87 8a ae 06 fd 01 1c 5e 0b ae 71 9f 
	Digest:     66 d4 43 d4 4e 94 a0 be 9c 7a 86 67 8b ce 63 2f 
	            3d 11 66 a1 01 fb a7 24 a3 f4 dc 5c 53 03 32 9e 


exit
```


