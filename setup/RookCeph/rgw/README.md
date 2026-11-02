# Rook Ceph RGW support

This directory contains the manifests and helper script needed to configure an external Ceph Object Gateway (RGW) as a bucket backend for MicroK8s.

## What is included

- `RookCeph_rgw.sh`: applies or removes the RGW manifests in this directory.
- `10_ceph-object-store.yaml`: defines the external CephObjectStore backing the RGW endpoint.
- `20_ceph-storage-class.yaml`: exposes a Kubernetes `StorageClass` for bucket provisioning.
- `30_rook-ceph-external_manifest.yaml`: RBAC and secret-store configuration for the external cluster access.
- `40_microceph-user.yaml`: external secret definition for the MicroCeph user credentials.
- `50_rgw-admin-ops-user.yaml`: external secret definition for the RGW admin operations user.
- `60_test-velero.yaml`: external secret definition used for Velero-related testing.
- `test/storage-bucket.yaml`: a sample `ObjectBucketClaim` used to validate bucket provisioning.

## Prerequisites

- A working MicroK8s installation.
- Access to an external Ceph cluster with RGW enabled.
- The `microk8s` CLI available in your PATH, or sudo access that allows `sudo microk8s`.
- The namespace `rook-ceph-external` available in the cluster.
- Any required external secret backend (for example OpenBao/External Secrets) already configured.

## Usage

Apply the manifests in this directory:

```bash
cd /path/to/setup/RookCeph/rgw
chmod +x RookCeph_rgw.sh
./RookCeph_rgw.sh
```

Remove the manifests:

```bash
./RookCeph_rgw.sh --delete
```

Include the example test bucket claim as well:

```bash
./RookCeph_rgw.sh --include-test
```

Preview the commands without executing them:

```bash
./RookCeph_rgw.sh --dry-run
```

## Notes

- By default, the script applies only the YAML files in this directory root and ignores the nested `test/` directory.
- The `test/` manifests are intentionally kept separate so a deployment does not accidentally create sample bucket claims during normal operations.
- For a full validation flow, apply the test bucket claim separately after the main configuration is in place.

## Verification

Check that the RGW object store and bucket storage class are registered:

```bash
sudo microk8s kubectl -n rook-ceph-external get cephobjectstore
sudo microk8s kubectl get storageclass
```

Validate the sample bucket creation:

```bash
sudo microk8s kubectl apply -f test/storage-bucket.yaml
sudo microk8s kubectl get objectbucketclaim -A
```

## Troubleshooting

If the manifests fail, check the following:

- `microk8s` is installed and the current user can access it.
- The namespace `rook-ceph-external` exists.
- The RGW endpoint in `10_ceph-object-store.yaml` is reachable and correct.
- The external secret store configuration matches your cluster setup.
- The storage class name in the test claim matches the provisioner configured by `20_ceph-storage-class.yaml`.

## Cleanup

To remove the temporary sample bucket claim:

```bash
sudo microk8s kubectl delete -f test/storage-bucket.yaml --ignore-not-found=true
```
