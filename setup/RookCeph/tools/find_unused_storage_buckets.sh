#!/bin/bash
############################################################################################
#
# Find unused storage buckets in Ceph external cluster
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
shopt -o -s nounset #-No Variables without definition
indir="$(pwd)"

namespace="${NAMESPACE:-rook-ceph-external}"
podname="${PODNAME:-rook-ceph-tools}"

if ! command -v sudo microk8s >/dev/null 2>&1 && ! command -v kubectl >/dev/null 2>&1; then
  echo "Error: neither sudo microk8s nor kubectl is available in PATH." >&2
  exit 1
fi

kubectl_cmd="kubectl"
if command -v sudo microk8s >/dev/null 2>&1; then
  kubectl_cmd="sudo microk8s kubectl"
fi

echo "Looking for pod matching '${podname}' in namespace '${namespace}'..."
mypod=$($kubectl_cmd get pod -n "${namespace}" --no-headers 2>/dev/null | grep -i "${podname}" | awk '{print $1}' || true)
if [ -z "${mypod}" ]; then
  echo "Error: No pod matching '${podname}' found in namespace '${namespace}'." >&2
  $kubectl_cmd get pods -n "${namespace}" || true
  exit 2
fi

# Auf dem MicroK8s-Host ausführen:
k8s_buckets=$($kubectl_cmd get buckets.objectstorage.k8s.io -o jsonpath='{.items[*].metadata.name}')
echo "K8s COSI Buckets: $k8s_buckets"

cmd="xbucket=\"$k8s_buckets\"
for bucket in \$(radosgw-admin bucket list | jq -r '.[]'); do
  if [[ ! \" \$xbucket \" =~ \" \$bucket \" ]]; then
    echo \"⚠️ unused bucket: \$bucket\"
  fi
done"

echo "Connecting to pod '${mypod}'..."
echo " "
$kubectl_cmd exec -it -n "${namespace}" "${mypod}" -- bash -c "$cmd"

cat <<EOF

⚠️  Note: The above list of unused buckets is based on the current state of the Ceph external cluster and the Kubernetes COSI buckets. 
Please review the list carefully before taking any action, as deleting buckets may result in data loss. 
Ensure that you have proper backups and understand the implications of removing any buckets before proceeding.

EOF

exit