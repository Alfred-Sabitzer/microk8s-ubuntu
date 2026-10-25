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
#git clone --depth=1 github.com/kubernetes-sigs/container-object-storage-interface


tar -xf container-object-storage-interface.tar.xz

# 2. Wechseln Sie in den Ordner
cd container-object-storage-interface

# 3. Führen Sie kustomize (apply -k) direkt auf das lokale Verzeichnis aus
${KUBECTL_CMD} apply -k . --namespace=container-object-storage-interface

# 2. Überprüfen, ob der Controller korrekt läuft
${KUBECTL_CMD} rollout status deployment container-object-storage-controller -n container-object-storage-interface --timeout=90s
${KUBECTL_CMD} get pods -n container-object-storage-interface

cd ..

${KUBECTL_CMD} apply -f 10_cosi_driver.yaml
${KUBECTL_CMD} apply -f 20_bucket_class.yaml
