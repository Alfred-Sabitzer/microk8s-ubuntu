#!/bin/bash
############################################################################################
#
# Install ceph manually
# follow https://www.rook.io/docs/rook/v1.13/CRDs/Cluster/external-cluster/#prerequisites
# Usage:
#   sudo ./ceph_test.sh
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
shopt -o -s nounset #-No Variables without definition
indir="$(pwd)"

source /etc/ceph/vars_${K8S_ENVIRONMENT}.sh
export external_namespace="rook-ceph-external"

# Delete Namespace Finalizers
delete_namespace() {
    IFS=" "
    local mynamespace="${1}"
    while read api
    do
        # echo "Checking $api in namespace ${mynamespace}..."
        while read NAMEITEM AGE
        do
            echo "deleting ${NAMEITEM}"
            # patch finalizers:
            kubectl patch ${api}/${NAMEITEM} -n ${mynamespace} \
                -p '{"metadata":{"finalizers":[]}}' --type=merge
            # Remove Namespace Finalizers
            #kubectl get namespace ${mynamespace} -o json \
            #| jq 'del(.spec.finalizers)' \
            #| kubectl replace --raw "/api/v1/namespaces/${mynamespace}/finalize" -f -
            # Clean Up Stuck Resources
            echo "kubectl delete ${api} -n ${mynamespace} ${NAMEITEM} --ignore-not-found"
            kubectl delete ${api} -n ${mynamespace} ${NAMEITEM} --ignore-not-found
        done < <(kubectl get -n ${mynamespace} $api --ignore-not-found  | grep -v NAME )
    done < <(kubectl api-resources --verbs=list --namespaced -o name | grep -v NAME )
}
#
# Cleanup any previous installs
#
microk8s disable rook-ceph --force
echo ""
echo "Cleanup previous rook-ceph and rook-ceph-cluster installs in k8s cluster namespace '${NAMESPACE}'"
echo ""
helm uninstall rook-ceph -n ${NAMESPACE} --ignore-not-found --timeout 300s 
helm uninstall rook-ceph-cluster -n ${external_namespace} --ignore-not-found --timeout 300s 
echo ""
echo "delete namespace '${NAMESPACE}'"
echo ""
delete_namespace ${NAMESPACE}
microk8s kubectl delete namespace ${NAMESPACE} --force --timeout 300s --ignore-not-found
echo ""
echo "delete namespace '${external_namespace}'"
echo ""
delete_namespace ${external_namespace} 
microk8s kubectl delete namespace ${external_namespace} --force --timeout 300s --ignore-not-found
#
microk8s kubectl delete storageclass ceph-rbd --ignore-not-found
microk8s kubectl delete storageclass cephfs --ignore-not-found
sleep 10

# Install rook-ceph via helm
echo ""
echo "install rook-ceph '${NAMESPACE}'"
echo ""
# cd ${HOME}/ceph/rook/deploy/charts/rook-ceph
# helm install --create-namespace --namespace ${NAMESPACE} rook-ceph rook-release/rook-ceph \
#     --set csi.kubeletDirPath=/var/snap/microk8s/common/var/lib/kubelet \
#     -f values.yaml
microk8s enable rook-ceph --rook-version v1.18.7

sleep 20
echo ""
echo "Wait until pods ready '${NAMESPACE}'"
echo ""
microk8s kubectl wait --for=condition=Ready pod --all -n "${NAMESPACE}" --timeout="300s"

#
# cd ${HOME}/ceph/rook/deploy/examples/
# echo ""
# echo "Import external cluster into k8s cluster namespace '${NAMESPACE}'"
# echo ""
# chmod 755 ./import-external-cluster.sh
# ./import-external-cluster.sh
#
# Now lets check
echo ""
echo "Check created configmagps in k8s cluster namespace '${NAMESPACE}'"
echo ""
microk8s kubectl get configmaps -n ${NAMESPACE}

#ansible@k8stest:~/gitlab/microk8s-ubuntu/setup/RookCeph$ k get configmaps -n rook-ceph
#NAME                            DATA   AGE
#external-cluster-user-command   1      7m54s
#kube-root-ca.crt                1      7m55s
#rook-ceph-mon-endpoints         3      7m55s

echo ""
echo "Check created secrets in k8s cluster namespace '${NAMESPACE}'"
echo ""
microk8s kubectl get secrets -n ${NAMESPACE}
#ansible@k8stest:~/gitlab/microk8s-ubuntu/setup/RookCeph$ k get secrets -n rook-ceph
#NAME                          TYPE                 DATA   AGE
#rook-ceph-mon                 kubernetes.io/rook   6      8m3s
#rook-csi-cephfs-node          kubernetes.io/rook   2      8m1s
#rook-csi-cephfs-provisioner   kubernetes.io/rook   2      8m1s
#rook-csi-rbd-node             kubernetes.io/rook   2      8m2s
#rook-csi-rbd-provisioner      kubernetes.io/rook   2      8m2s

echo ""
echo "Check created storageclasses in k8s cluster namespace '${NAMESPACE}'"
echo ""
microk8s kubectl get storageclasses.storage.k8s.io -n ${NAMESPACE}
#ansible@k8stest:~/gitlab/microk8s-ubuntu/setup/RookCeph$ k get storageclasses.storage.k8s.io -n rook-ceph
#NAME                PROVISIONER                     RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
#ceph-rbd            rook-ceph.rbd.csi.ceph.com      Delete          Immediate              true                   8m8s
#cephfs              rook-ceph.cephfs.csi.ceph.com   Delete          Immediate              true                   6h45m
#microk8s-hostpath   microk8s.io/hostpath            Delete          WaitForFirstConsumer   false                  8h
#ansible@k8stest:~/gitlab/microk8s-ubuntu/setup/RookCeph$

echo "Patching storageclasses defaults (if present)..."
# attempt to make ceph-rbd default and unset hostpath default if present
microk8s kubectl patch storageclass microk8s-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}' || true
microk8s kubectl patch storageclass ceph-rbd -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' || true

# Patch cephfs storageclass and adopt file system and pool names
# microk8s kubectl get storageclasses.storage.k8s.io cephfs -o yaml > /tmp/cephfs_sc.yaml
# sed -i "s/.*fsName:.*/    fsName: ${CEPHFS_FS_NAME}/" /tmp/cephfs_sc.yaml
# sed -i "s/.*fsName:.*/    pool: ${CEPHFS_POOL_NAME}/" /tmp/cephfs_sc.yaml
# microk8s kubectl apply -f /tmp/cephfs_sc.yaml

# check
echo ""
echo "Check created resources in k8s cluster namespace '${NAMESPACE}'"
echo ""
microk8s kubectl get all -n ${NAMESPACE}
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

# Install rook-ceph-cluster via helm
echo ""
echo "install rook-ceph-cluster '${external_namespace}'"
echo ""
# cd ${HOME}/ceph/rook/deploy/charts/rook-ceph-cluster
# helm install --create-namespace --namespace $external_namespace rook-ceph-external rook-release/rook-ceph-cluster -f values-external.yaml
# sleep 10
# echo ""
# echo "Wait until pods ready '${external_namespace}'"
# echo ""
# microk8s kubectl wait --for=condition=Ready pod --all -n "${external_namespace}" --timeout="300s"

# Optional: connect to external Ceph cluster if files provided
CEPh_CONF="/etc/ceph/ceph.conf"
CEPh_KEYRING="/etc/ceph/ceph.keyring"
RBD_POOL="${K8S_ENVIRONMENT}-rbd"

microk8s connect-external-ceph \
    --ceph-conf "${CEPh_CONF}" \
    --keyring "${CEPh_KEYRING}" \
    --rbd-pool "${RBD_POOL}"

microk8s kubectl wait --for=condition=Ready pod --all -n "${external_namespace}" --timeout="300s"

#
#check
#
echo ""
echo "Check created cluster in k8s cluster namespace '${external_namespace}'"
echo ""
microk8s kubectl get cephcluster -n ${external_namespace}
#ansible@k8stest:~/ceph/rook/deploy/charts/rook-ceph-cluster$ kubectl --namespace rook-ceph get cephcluster
#NAME        DATADIRHOSTPATH   MONCOUNT   AGE   PHASE       MESSAGE                          HEALTH      EXTERNAL   FSID
#rook-ceph   /var/lib/rook     3          42s   Connected   Cluster connected successfully   HEALTH_OK   true       7ca92fa6-c971-4091-8d6d-741175f39e78
#
echo ""
echo "Check created resources in k8s cluster namespace '${NAMESPACE}'"
echo ""
microk8s kubectl get all -n ${NAMESPACE}
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
