# Rook Ceph cosi support

This directory contains the manifests and helper script needed to configure an external Ceph Object Gateway (RGW) as a bucket backend for MicroK8s.

There is no git on the target-machines, therefore we add the sources as tar-file.

Please note: the kustomization.yaml has been modified:

````yaml
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

commonAnnotations:
  objectstorage.k8s.io/authors: "Kubernetes Authors"
  objectstorage.k8s.io/license: "Apache V2"
  objectstorage.k8s.io/support: "https://github.com/kubernetes-sigs/container-object-storage-api"

# Define the right namespace
namespace: container-object-storage-interface

resources:
  # ensure all resources begin with './'
  - ./client/config/crd
  - ./controller
---  
````
