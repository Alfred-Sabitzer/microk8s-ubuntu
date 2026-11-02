# csi-s3 validation manifests

This directory contains sample resources used to validate the S3 CSI driver in a test namespace. These files are intentionally kept separate from the installation manifests in the parent directory.

## Included files

- `namespace.yaml` - creates the `test` namespace
- `harbor-pull.yaml` - pull secret used by the validation workload
- `harbor-cosign.yaml` - image signature access for the same workload
- `rbac.yaml` - namespace-level RBAC for test automation
- `deployment.yaml` - sample pod that mounts a PVC backed by the S3 storage class
- `test_manifest.yaml` - extra workload manifest kept for ad-hoc testing

## Purpose

The manifests here are meant to exercise an S3-backed PVC after the main `csi-s3` driver installation succeeds. They are not required for the base setup and should be applied only in controlled validation environments.

## Prerequisites

- The main `csi-s3` installation has completed successfully.
- The S3 CSI storage class exists and is usable in the cluster.
- The `test` namespace is available or created by `namespace.yaml`.
- Any pull secrets referenced in the deployment exist in the cluster.

## Usage

Create the test namespace and apply the supporting manifests:

```bash
cd /path/to/setup/RookCeph/csi-s3
sudo microk8s kubectl apply -f test/namespace.yaml
sudo microk8s kubectl apply -f test/harbor-pull.yaml
sudo microk8s kubectl apply -f test/harbor-cosign.yaml
sudo microk8s kubectl apply -f test/rbac.yaml
```

Then deploy the example workload:

```bash
sudo microk8s kubectl apply -f test/deployment.yaml
```

Check the pod and PVC status:

```bash
sudo microk8s kubectl -n test get pods
sudo microk8s kubectl -n test get pvc
```

Remove the validation workload when finished:

```bash
sudo microk8s kubectl delete -f test/deployment.yaml --ignore-not-found=true
```

## Notes

- The PVC in `deployment.yaml` is named `ceph-s3-pvc` and expects the S3 storage class to provide a `ReadWriteMany` mount.
- The namespace `test` should only be used for temporary validation; adjust it if your environment already has a different target namespace.
- The `test_manifest.yaml` file is a sample bundle and may be used when you want to apply the test resources as a single object.
