# Velero deployment

This folder contains a small Velero deployment stack for MicroK8s that:

- creates the Velero and Velero UI namespaces
- provisions the supporting Kubernetes resources for External Secrets / OpenBao integration
- applies the Velero backup storage and snapshot location manifests
- installs Velero and the Velero UI Helm charts

## Prerequisites

Before running the scripts, make sure the following are available:

- MicroK8s with Helm and kubectl available through the MicroK8s snap
- a working S3-compatible object storage endpoint (for example MicroCeph RadosGW)
- the External Secrets and OpenBao integrations already configured in the cluster
- the required tools installed locally: envsubst, s3cmd, and sudo

## Files

- [velero.sh](velero.sh) applies the manifests in this folder and installs the Helm charts.
- [Velero_create_buckets.sh](Velero_create_buckets.sh) creates the object storage bucket and the RadosGW user expected by Velero.
- [10_velero_namespace.yaml](10_velero_namespace.yaml) creates the Velero namespaces.
- [20-velero_manifest.yaml](20-velero_manifest.yaml) and [30-velero-ui_manifest.yaml](30-velero-ui_manifest.yaml) create supporting service accounts, roles, bindings and secret stores.
- [40-velero.yaml](40-velero.yaml), [40-velero-ui.yaml](40-velero-ui.yaml), and [40-velero-bucket-meta.yaml](40-velero-bucket-meta.yaml) wire up the required secrets and bucket metadata.
- [50_velero-virtual-service-mutual.yaml](50_velero-virtual-service-mutual.yaml), [70-velero-snapshot-location.yaml](70-velero-snapshot-location.yaml), [80-velero-backup-storage-location.yaml](80-velero-backup-storage-location.yaml), and [90-velero-backup.yaml](90-velero-backup.yaml) define the UI route and Velero backup policy.

## Configuration

The deployment is parameterized with environment variables so the same manifests can be reused across environments.

- K8S_ENVIRONMENT: environment name used in resource names and default hostnames (default: test)
- VELERO_NAMESPACE: namespace used for the Velero control plane (default: velero)
- VELERO_UI_NAMESPACE: namespace used for the Velero UI (default: velero-ui)
- VELERO_BACKUP_LOCATION_NAME: name of the backup storage location and volume snapshot location (default: ${K8S_ENVIRONMENT}-velero)
- VELERO_BUCKET_NAME: S3 bucket name used by Velero (default: ${K8S_ENVIRONMENT}-velero)
- VELERO_UI_HOST: hostname for the UI ingress route (default: velero-ui.${K8S_ENVIRONMENT}.slainte.at)
- S3_ENDPOINT: S3-compatible endpoint URL (default: http://192.168.0.194:8081)
- S3_REGION: S3 region used by the backup location (default: default)

## Quick start

1. Create the object storage bucket and access credentials:

   sudo ./Velero_create_buckets.sh

2. Apply the manifests and install Velero:

   sudo ./velero.sh

3. Verify the resources in the cluster:

   sudo microk8s kubectl get pods -n velero
   sudo microk8s kubectl get backupstoragelocations.velero.io -n velero

## Notes

- The manifests rely on the External Secrets integration to populate the `velero` and `velero-ui` secrets. Make sure the referenced OpenBao/External Secret roles exist before running the deployment.
- The S3 endpoint and bucket name in the scripts must match the values used by your object storage backend.
- The backup schedule is disabled by default in the manifest and can be enabled or adjusted in [90-velero-backup.yaml](90-velero-backup.yaml).
