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

## Generic s3-driver

This is to avoid the sidecar-approach

````bash
---
 repo add csi-s3 https://github.io
microk8s helm install csi-s3 csi-s3/csi-s3 \
  --set kubeletDir=/var/snap/microk8s/common/var/lib/kubelet
````

The neede yaml-definitions are


````yaml
---
 v1
kind: Secret
metadata:
  name: ceph-s3-creds
  namespace: default
stringData:
  # Ersetze diese Werte mit deinen echten Ceph-S3-Keys
  accessKeyID: "USER_ACCESS_KEY_HIER"
  secretAccessKey: "USER_SECRET_KEY_HIER"
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ceph-s3-storage
provisioner: ch.ctrox.csi.s3-driver # Name des installierten csi-s3 Treibers
parameters:
  # Die HTTP(S) URL deines Ceph RADOS Gateways (RGW)
  endpoint: "http://ceph-rgw-service.local:8000"
  # Welcher FUSE-Mounter genutzt werden soll (geesefs ist für Ceph/S3 meist am schnellsten)
  mounter: geesefs 
  # Region kann bei Ceph oft leer oder auf "us-east-1" (Default) bleiben
  region: "us-east-1"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ceph-s3-pvc
  namespace: default
spec:
  accessModes:
    - ReadWriteMany # S3 erlaubt standardmäßig den Zugriff von vielen Pods gleichzeitig
  storageClassName: ceph-s3-storage
  resources:
    requests:
      # Da S3 unendlich skaliert, ist die Angabe für Ceph rein symbolisch für K8s
      storage: 50Gi 
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: s3-app-deployment
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: s3-app
  template:
    metadata:
      labels:
        app: s3-app
    spec:
      containers:
      - name: app-container
        image: ubuntu:latest
        command: ["/bin/sh", "-c", "while true; do sleep 30; done"] # Hält den Container aktiv
        volumeMounts:
        - name: s3-volume
          mountPath: /var/meine-app/daten # Hier wird dein Ceph-Bucket als Ordner sichtbar!
      volumes:
      - name: s3-volume
        persistentVolumeClaim:
          claimName: ceph-s3-pvc # Verweis auf das PVC von oben
---
````

