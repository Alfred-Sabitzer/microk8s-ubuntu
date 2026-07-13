#!/bin/bash
############################################################################################
#
# Install and configure csi snapshot with Rook/Ceph integration on MicroK8s.
#
############################################################################################
set -euo pipefail
trap 'rc=$?; echo "Exiting with status $rc"; exit $rc' EXIT

KUBECTL_CMD="sudo microk8s kubectl"

echo "Install the snapshot CRDs:"

$KUBECTL_CMD apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/master/client/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml
$KUBECTL_CMD apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/master/client/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml
$KUBECTL_CMD apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/master/client/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml

echo "Deploy the snapshot-controller:"

$KUBECTL_CMD apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/master/deploy/kubernetes/snapshot-controller/rbac-snapshot-controller.yaml
$KUBECTL_CMD apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/master/deploy/kubernetes/snapshot-controller/setup-snapshot-controller.yaml

echo "Finding YAML files in ${indir}..."
  mapfile -t yamls < <(find "${indir}" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort)

  if [ "${#yamls[@]}" -eq 0 ]; then
    echo "INFO: No YAML files found in ${indir}"
  else 
    echo "Found ${#yamls[@]} YAML file(s)."
    echo ""
    echo "========== Applying YAML Resources =========="
    for f in "${yamls[@]}"; do
      echo ""
      echo "Applying: $f"
      if ! retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" envsubst < "$f" | $KUBECTL_CMD apply -f - ; then
        die "Failed to apply $f after $RETRY_ATTEMPTS attempts"
      fi
    done
  fi


echo "Verify the installation:"

$KUBECTL_CMD api-resources | grep volumesnapshot

exit