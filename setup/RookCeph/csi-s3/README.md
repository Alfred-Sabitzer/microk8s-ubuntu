# Rook Ceph S3 CSI driver

This directory configures the `k8s-csi-s3` CSI driver for a MicroK8s cluster that already has an external Ceph RGW / Rook object store. The setup is intentionally minimal:

- create a CephObjectStoreUser for S3 bucket provisioning
- install the Helm chart for the CSI driver
- leave the sample validation manifests in `test/` separate from the live configuration

## Included files

- `csi-s3.sh` - applies the Ceph user and installs the CSI driver
- `20_ceph_object_store_user.yaml` - Rook Ceph user used for object storage access
- `test/` - example manifests for a validation workload using a mounted bucket

## Prerequisites

- A working MicroK8s installation
- An external Rook Ceph cluster with RGW enabled and a store named `external-store`
- The namespace `rook-ceph-external` exists and is usable
- `microk8s`, `kubectl`, `helm`, and `envsubst` are available on the host

## What the script does

The script:

1. applies the CephObjectStoreUser manifest in the `rook-ceph-external` namespace
2. removes any previous `csi-s3` Helm release in that namespace
3. adds the upstream Helm repo for `k8s-csi-s3`
4. installs the CSI driver with the MicroK8s kubelet path

## Usage

```bash
cd /path/to/setup/RookCeph/csi-s3
chmod +x csi-s3.sh
./csi-s3.sh
```

You can override the default namespace and endpoint before running it:

```bash
export NAMESPACE=rook-ceph-external
export S3_ENDPOINT=http://192.168.0.194:8081
export S3_REGION=default
export S3_SECRET=rook-ceph-object-user-external-store-csi-s3
./csi-s3.sh
```

## Verification

Check that the object user exists:

```bash
sudo microk8s kubectl -n rook-ceph-external get cephobjectstoreuser csi-s3
```

Check the installed Helm release and driver pods:

```bash
sudo microk8s helm list -n rook-ceph-external
sudo microk8s kubectl -n rook-ceph-external get pods | grep csi-s3
```

The chart creates the storage class and secret wiring required by the S3 CSI driver. The exact storage class name depends on the chart values; inspect the chart output and cluster objects once the install finishes.

## Validation manifests

The manifests under `test/` are not part of the normal deployment and are intended for a focused validation workload. They create a test namespace, image pull secrets, RBAC, and a sample pod that mounts a PVC backed by the S3 storage class.

Apply them only after the principal installation succeeds:

```bash
sudo microk8s kubectl apply -f test/namespace.yaml
sudo microk8s kubectl apply -f test/harbor-pull.yaml
sudo microk8s kubectl apply -f test/harbor-cosign.yaml
sudo microk8s kubectl apply -f test/rbac.yaml
sudo microk8s kubectl apply -f test/deployment.yaml
```

## Notes

- This folder assumes the RGW object store already exists and is exposed as `external-store`.
- The chart and manifests intentionally separate the live S3 CSI installation from the test workload manifests.
- If your environment uses a different namespace or endpoint, adjust the exported environment variables before running the script.

