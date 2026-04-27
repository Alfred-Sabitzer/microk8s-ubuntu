#!/bin/sh
# connect into container
KUBECTL="sudo microk8s kubectl"
namespace="${NAMESPACE:-openbao}"
podname="${POD_NAME:-openbao}"
mypod=$(${KUBECTL} get pod -n "${namespace}" --no-headers -o custom-columns=NAME:.metadata.name | grep -i "${podname}" | awk '{print $1}')
if [ -z "${mypod:-}" ]; then
  echo "No pod found matching ${podname} in namespace ${namespace}" >&2
  exit 1
fi
${KUBECTL} exec -it -n "${namespace}" "${mypod}" -c "${podname}" -- sh -c "clear; (bash || ash || sh)"
