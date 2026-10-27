#!/usr/bin/env bash
############################################################################################
#
# Apply or remove cosi manifests for a Rook/Ceph external cluster.
#
############################################################################################
set -Eeuo pipefail

KUBECTL_CMD="sudo microk8s kubectl"

# create namespace for COSI if it doesn't exist
cat << EOF | ${KUBECTL_CMD} apply -f -
---
apiVersion: v1
kind: Namespace
metadata:
  labels:
    kubernetes.io/metadata.name: container-object-storage-interface
    monitoring: enabled
    name: container-object-storage-interface
    istio-injection: disabled
    istio.io/dataplane-mode: none
  name: container-object-storage-interface
spec:
  finalizers:
    - kubernetes
---
EOF


# Install CRDs und Kern-Controller für das COSI-Framework
# git clone --depth=1 github.com/kubernetes-sigs/container-object-storage-interface -> Variant: v1alpha2 -> Leads to the following error: "error: unable to recognize "": no matches for kind "BucketClass" in version "cosi.io/v1alpha2""
# https://github.com/kubernetes-sigs/container-object-storage-interface.git
# https://github.com/kubernetes-sigs/container-object-storage-interface/tree/dependabot/docker/controller/resources/k8s-staging-sig-storage/objectstorage-controller-v20261023-controllerv0.2.0-rc1-354-g274540c

# https://github.com/kubernetes-sigs/container-object-storage-interface/tree/release-0.2 -> Variant: v1alpha1

tar -xf container-object-storage-interface-release-0.2.tar.xz


# # 2. Wechseln Sie in den Ordner
cd container-object-storage-interface-release-0.2 

# Find all Bucket and BucketAccess CRD manifests
find . -type f \( -iname '*bucket*crd*.yaml' \
  -o -iname '*bucket*crd*.yml' \
  -o -iname '*bucketaccess*.yaml' \
  -o -iname '*bucketaccess*.yml' \) -print

cat ./client/config/crd/objectstorage.k8s.io_bucketaccesses.yaml | grep -i '\- name:'


# # 3. Führen Sie kustomize (apply -k) direkt auf das lokale Verzeichnis aus
${KUBECTL_CMD} apply -k . --namespace=container-object-storage-interface

# 2. Überprüfen, ob der Controller korrekt läuft
${KUBECTL_CMD} rollout status deployment container-object-storage-controller -n container-object-storage-interface --timeout=90s
${KUBECTL_CMD} get pods -n container-object-storage-interface

cd ..

${KUBECTL_CMD} apply -f 10_cosi_driver.yaml
${KUBECTL_CMD} apply -f 20_bucket_class.yaml


${KUBECTL_CMD} get crd | grep objectstorage.k8s.io

${KUBECTL_CMD} api-resources --api-group=objectstorage.k8s.io

${KUBECTL_CMD} get deployments -A | grep container-object-storage