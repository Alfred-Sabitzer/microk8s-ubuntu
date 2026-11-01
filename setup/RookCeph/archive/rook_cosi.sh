#!/bin/bash
############################################################################################
#
# Additional add for COSI (Container Object Storage Interface) for Rook/Ceph in a MicroK8S cluster.
#
############################################################################################
set -euo pipefail
trap 'rc=$?; echo "Exiting with status $rc"; exit $rc' EXIT

sudo microk8s helm3 upgrade rook-ceph rook-release/rook-ceph \
  --namespace rook-ceph \
  --reuse-values \
  --set cosi.enabled=true \
  --set csi.kubeletDirPath=/var/snap/microk8s/common/var/lib/kubelet

# ansible@k8stest:~$ sudo microk8s helm3 upgrade rook-ceph rook-release/rook-ceph   --namespace rook-ceph   --reuse-values   --set cosi.enabled=true   --set csi.kubeletDirPath=/var/snap/microk8s/common/var/lib/kubelet
# Release "rook-ceph" has been upgraded. Happy Helming!
# NAME: rook-ceph
# LAST DEPLOYED: Tue Oct 27 07:35:42 2026
# NAMESPACE: rook-ceph
# STATUS: deployed
# REVISION: 2
# TEST SUITE: None
# NOTES:
# The Rook Operator has been installed.

# Visit https://rook.io/docs/rook/latest for instructions on how to create and configure Rook clusters

# Important Notes:
# - You must customize the 'CephCluster' resource in the sample manifests for your cluster.
# - Each CephCluster must be deployed to its own namespace, the samples use `rook-ceph` for the namespace.
# - The sample manifests assume you also installed the rook-ceph operator in the `rook-ceph` namespace.
# - The helm chart includes all the RBAC required to create a CephCluster CRD in the same namespace.
# - Any disk devices you add to the cluster in the 'CephCluster' must be empty (no filesystem and no partitions).
# ansible@k8stest:~$ 
