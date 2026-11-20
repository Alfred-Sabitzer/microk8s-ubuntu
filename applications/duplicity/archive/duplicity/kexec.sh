#!/bin/sh
# connect into container
KUBECTL="sudo microk8s kubectl"
namespace="${NAMESPACE:-velero}"
podname="${POD_NAME:-duplicity}"
mycontainer="${CONTAINER_NAME:-duplicity}"
mypod=$(${KUBECTL} get pod -n ${namespace} | grep -i ${podname} | awk '{print $1 }')
if [ -z "${mypod:-}" ]; then
  echo "No pod found matching ${podname} in namespace ${namespace}" >&2
  exit 1
fi
${KUBECTL} exec -it -n "${namespace}" "${mypod}" -c ""${mycontainer}"" -- sh -c "clear; (bash || ash || sh)"