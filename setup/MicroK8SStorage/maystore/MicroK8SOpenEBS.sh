#!/bin/bash
############################################################################################
#
# MicroK8S OpenEBS https://microk8s.io/docs/addon-openebs
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition
indir=$(dirname "$0")
microk8s enable hostpath-storage                    # (core) Storage class; allocates storage from host directory
# Disable and enable OpenEBS
microk8s disable openebs:force
microk8s enable openebs                             # (community) OpenEBS is the open-source storage solution for Kubernetes
kubectl get storageclasses.storage.k8s.io
# Patchen der Default-Class
kubectl patch storageclass microk8s-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
kubectl patch storageclass openebs-jiva-csi-default -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl patch storageclass openebs-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
kubectl get storageclasses.storage.k8s.io
# Setzen des Basis-Pfades auf die SSD
#kubectl get storageclass openebs-hostpath -o yaml > /tmp/openebs-hostpath.yaml
#sed --in-place  "s,/var/snap/microk8s/common/var/openebs/local,/mnt/data/openebs,g" /tmp/openebs-hostpath.yaml
#kubectl apply -f /tmp/openebs-hostpath.yaml
#rm -f /tmp/openebs-hostpath.yaml
#
# Jetzt haben wir ClusterStorage
#