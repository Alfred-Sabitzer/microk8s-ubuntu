# RGW test manifests

This directory contains example resources used to validate bucket provisioning and RGW connectivity for the external Rook Ceph setup in the parent directory.

## Included files

- `storage-bucket.yaml`: creates an `ObjectBucketClaim` named `test-bucket` in the `default` namespace.

## Purpose

These manifests are intentionally kept separate from the main deployment manifests so they can be used for verification without affecting normal cluster configuration.

## Prerequisites

- The parent RGW configuration has already been applied successfully.
- The `ceph-bucket` `StorageClass` exists and is usable.
- Your MicroK8s cluster has the required object bucket provisioner installed and working.

## Usage

Apply the sample bucket claim:

```bash
cd /path/to/setup/RookCeph/rgw
sudo microk8s kubectl apply -f test/storage-bucket.yaml
```

Check that the bucket claim is bound and the corresponding bucket resources are created:

```bash
sudo microk8s kubectl get objectbucketclaim -A
sudo microk8s kubectl get secret -A | grep -i bucket
```

To remove the test object bucket claim:

```bash
sudo microk8s kubectl delete -f test/storage-bucket.yaml --ignore-not-found=true
```

## Notes

- This directory is excluded by default when running the parent script via `RookCeph_rgw.sh`.
- The sample name and namespace may need to be adjusted for your environment if you already use `test-bucket` or prefer a different namespace.
- Treat these resources as temporary validation objects only.
