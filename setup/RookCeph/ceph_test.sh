ansible@lxd:~/ceph$ cat ceph_test.sh 

#!/bin/bash
############################################################################################
#
# Install ceph manually
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
shopt -o -s nounset #-No Variables without definition
indir="$(pwd)"

#ansible@micro1:~/ceph$ sudo python3 ./create-external-cluster-resources.py --rbd-data-pool-name test-rbd --namespace rook-ceph --cephfs-filesystem-name cephfs --format bash
#export ARGS="[Configurations]
#namespace = rook-ceph
#rgw-pool-prefix = default
#format = bash
helm repo add rook-release https://charts.rook.io/release
#cephfs-filesystem-name = cephfs
#cephfs-metadata-pool-name = cephfs_metadata
#cephfs-data-pool-name = cephfs_data
#rbd-data-pool-name = test-rbd
#"

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

export clusterNamespace=rook-ceph
export operatorNamespace=rook-ceph

cd ${indir}/rook/deploy/examples/
bash ./import-external-cluster.sh

#
# Now lets check
#ansible@k8stest:~/gitlab/microk8s-ubuntu/setup/RookCeph$ k get configmaps -n rook-ceph
#NAME                            DATA   AGE
#external-cluster-user-command   1      7m54s
#kube-root-ca.crt                1      7m55s
#rook-ceph-mon-endpoints         3      7m55s
#ansible@k8stest:~/gitlab/microk8s-ubuntu/setup/RookCeph$ k get secrets -n rook-ceph
#NAME                          TYPE                 DATA   AGE
#rook-ceph-mon                 kubernetes.io/rook   6      8m3s
#rook-csi-cephfs-node          kubernetes.io/rook   2      8m1s
#rook-csi-cephfs-provisioner   kubernetes.io/rook   2      8m1s
#rook-csi-rbd-node             kubernetes.io/rook   2      8m2s
#rook-csi-rbd-provisioner      kubernetes.io/rook   2      8m2s
#ansible@k8stest:~/gitlab/microk8s-ubuntu/setup/RookCeph$ k get storageclasses.storage.k8s.io -n rook-ceph
#NAME                PROVISIONER                     RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
#ceph-rbd            rook-ceph.rbd.csi.ceph.com      Delete          Immediate              true                   8m8s
#cephfs              rook-ceph.cephfs.csi.ceph.com   Delete          Immediate              true                   6h45m
#microk8s-hostpath   microk8s.io/hostpath            Delete          WaitForFirstConsumer   false                  8h
#ansible@k8stest:~/gitlab/microk8s-ubuntu/setup/RookCeph$

cd ${indir}/rook/deploy/charts/rook-ceph
helm install --create-namespace --namespace $clusterNamespace rook-ceph rook-release/rook-ceph -f values.yaml

# check
#ansible@k8stest:~/ceph/rook/deploy/charts/rook-ceph$ k get all -n rook-ceph
#NAME                                              READY   STATUS    RESTARTS   AGE
#pod/ceph-csi-controller-manager-78d4fd465-tpw4s   1/1     Running   0          33s
#pod/rook-ceph-operator-7fc848bf99-fprph           1/1     Running   0          33s
#
#NAME                                          READY   UP-TO-DATE   AVAILABLE   AGE
#deployment.apps/ceph-csi-controller-manager   1/1     1            1           33s
#deployment.apps/rook-ceph-operator            1/1     1            1           33s
#
#NAME                                                    DESIRED   CURRENT   READY   AGE
#replicaset.apps/ceph-csi-controller-manager-78d4fd465   1         1         1       33s
#replicaset.apps/rook-ceph-operator-7fc848bf99           1         1         1       33s
#ansible@k8stest:~/ceph/rook/deploy/charts/rook-ceph$

cd ${indir}/rook/deploy/charts/rook-ceph-cluster
helm install --create-namespace --namespace $clusterNamespace rook-ceph-cluster \
    --set operatorNamespace=$operatorNamespace rook-release/rook-ceph-cluster -f values-external.yaml

#
#check
#
#ansible@k8stest:~/ceph/rook/deploy/charts/rook-ceph-cluster$ kubectl --namespace rook-ceph get cephcluster
#NAME        DATADIRHOSTPATH   MONCOUNT   AGE   PHASE       MESSAGE                          HEALTH      EXTERNAL   FSID
#rook-ceph   /var/lib/rook     3          42s   Connected   Cluster connected successfully   HEALTH_OK   true       7ca92fa6-c971-4091-8d6d-741175f39e78
#
#ansible@k8stest:~/ceph/rook/deploy/charts/rook-ceph-cluster$ k get all -n rook-ceph
#NAME                                                           READY   STATUS    RESTARTS        AGE
#pod/ceph-csi-controller-manager-78d4fd465-tpw4s                1/1     Running   2 (2m22s ago)   6m44s
#pod/rook-ceph-operator-7fc848bf99-fprph                        1/1     Running   0               6m44s
#pod/rook-ceph.cephfs.csi.ceph.com-ctrlplugin-5456dbbd6-z4vxn   5/5     Running   0               3m46s
#pod/rook-ceph.cephfs.csi.ceph.com-nodeplugin-vfn69             2/2     Running   0               3m46s
#pod/rook-ceph.rbd.csi.ceph.com-ctrlplugin-58d6cb98cb-vbjhx     5/5     Running   0               3m46s
#pod/rook-ceph.rbd.csi.ceph.com-nodeplugin-q42j2                2/2     Running   0               3m46s
#
#NAME                                                      DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
#daemonset.apps/rook-ceph.cephfs.csi.ceph.com-nodeplugin   1         1         1       1            1           <none>          3m46s
#daemonset.apps/rook-ceph.rbd.csi.ceph.com-nodeplugin      1         1         1       1            1           <none>          3m46s
#
#NAME                                                       READY   UP-TO-DATE   AVAILABLE   AGE
#deployment.apps/ceph-csi-controller-manager                1/1     1            1           6m44s
#deployment.apps/rook-ceph-operator                         1/1     1            1           6m44s
#deployment.apps/rook-ceph.cephfs.csi.ceph.com-ctrlplugin   1/1     1            1           3m46s
#deployment.apps/rook-ceph.rbd.csi.ceph.com-ctrlplugin      1/1     1            1           3m46s
#
#NAME                                                                 DESIRED   CURRENT   READY   AGE
#replicaset.apps/ceph-csi-controller-manager-78d4fd465                1         1         1       6m44s
#replicaset.apps/rook-ceph-operator-7fc848bf99                        1         1         1       6m44s
#replicaset.apps/rook-ceph.cephfs.csi.ceph.com-ctrlplugin-5456dbbd6   1         1         1       3m46s
#replicaset.apps/rook-ceph.rbd.csi.ceph.com-ctrlplugin-58d6cb98cb     1         1         1       3m46s
#ansible@k8stest:~/ceph/rook/deploy/charts/rook-ceph-cluster$
