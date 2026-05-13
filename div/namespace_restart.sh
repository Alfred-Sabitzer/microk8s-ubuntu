#!/bin/bash
################################################################################
#
# Restart all controllers and pods in a namespace (default: observability)
# - rollout restart deployments/statefulsets
# - restart daemonsets (rollout restart or patch annotation)
# - delete pods without owners (standalone pods)
# - wait for resources to become Ready
#
################################################################################
shopt -o -s errexit   #—Terminates  the shell script if a command returns an error code.
#shopt -o -s xtrace    #—Displays each command before it is executed.
shopt -o -s nounset   #-No Variables without definition
set -euo pipefail
trap 'rc=$?; if [ $rc -ne 0 ]; then echo "Script failed with exit $rc" >&2; fi; exit $rc' EXIT

NS="${1:-observability}"
KUBECTL="${KUBECTL:-sudo microk8s kubectl}"
WAIT_SECONDS="${WAIT_SECONDS:-300}"
DRY_RUN=false
ASSUME_YES=false

usage(){
  cat <<EOF
Usage: $0 [namespace] [--wait <s>] [--dry-run] [--yes]
  namespace : Kubernetes namespace to operate on (default: observability)
  --wait    : seconds to wait for readiness after restart (default: ${WAIT_SECONDS})
  --dry-run : show actions without executing
  --yes     : skip confirmation prompt
EOF
}

# parse flags
while [ $# -gt 0 ]; do
  case "$1" in
    --wait) WAIT_SECONDS="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --yes) ASSUME_YES=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) # first positional (namespace) handled above; shift past it
       shift ;;
  esac
done

# detect kubectl
if [ -z "$KUBECTL" ]; then
  if command -v sudo microk8s >/dev/null 2>&1; then
    KUBECTL="sudo microk8s kubectl"
  elif command -v kubectl >/dev/null 2>&1; then
    KUBECTL="kubectl"
  else
    echo "Error: kubectl or sudo microk8s not found in PATH" >&2
    exit 2
  fi
fi

echo "Namespace: ${NS}"
echo "kubectl: ${KUBECTL}"
echo "Wait seconds: ${WAIT_SECONDS}"
echo "Dry-run: ${DRY_RUN}"

if [ "${ASSUME_YES}" = false ] && [ "${DRY_RUN}" = false ]; then
  read -r -p "Proceed to restart resources in namespace '${NS}'? [y/N] " ans
  case "$ans" in [Yy]*) ;; *) echo "Aborted."; exit 0 ;; esac
fi

run() {
  if [ "${DRY_RUN}" = true ]; then
    echo "[DRY-RUN] $*"
  else
    eval "$@"
  fi
}

ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# helper to iterate names for a resource kind
restart_rollout() {
  local kind="$1" # deployment|statefulset
  echo "Restarting ${kind}s..."
  names=$($KUBECTL -n "${NS}" get "${kind}" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || true)
  if [ -z "$names" ]; then
    echo "  no ${kind}s found in ${NS}"
    return
  fi
  for n in $names; do
    echo "  ${kind}/${n}"
    if ! run "${KUBECTL} -n ${NS} rollout restart ${kind}/${n}"; then
      # fallback: patch annotation to trigger pod template rollout
      echo "    rollout restart failed, patching annotation"
      run "${KUBECTL} -n ${NS} patch ${kind} ${n} -p '{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"restart-timestamp\":\"${ts}\"}}}}}'"
    fi
  done
}

# Deployments
restart_rollout deployment

# StatefulSets
restart_rollout statefulset

# DaemonSets: try rollout restart, else patch annotation
echo "Restarting daemonsets..."
ds_names=$($KUBECTL -n "${NS}" get daemonset -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || true)
if [ -n "${ds_names}" ]; then
  for ds in $ds_names; do
    echo "  daemonset/${ds}"
    if ! run "${KUBECTL} -n ${NS} rollout restart daemonset/${ds}"; then
      echo "    rollout restart not supported; patching annotation"
      run "${KUBECTL} -n ${NS} patch daemonset ${ds} -p '{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"restart-timestamp\":\"'"${ts}"'\"}}}}}'"
    fi
  done
else
  echo "  no daemonsets found in ${NS}"
fi

# Delete pods that have no ownerReferences (standalone pods)
echo "Deleting standalone pods (no ownerReferences)..."
pods_info=$($KUBECTL -n "${NS}" get pods -o jsonpath='{range .items[*]}{.metadata.name}";"{.metadata.ownerReferences[*].name}{"\n"}{end}' 2>/dev/null || true)
while IFS= read -r line; do
  [ -z "$line" ] && continue
  name=${line%%;*}
  owners=${line#*;}
  if [ -z "$owners" ]; then
    echo "  deleting pod ${name} (no owner)"
    run "${KUBECTL} -n ${NS} delete pod ${name} --grace-period=30 --timeout=120s" || true
  fi
done <<< "$pods_info"#!/bin/bash

sleep 10

echo "Waiting up to ${WAIT_SECONDS}s for pods to be Ready..."
if [ "${DRY_RUN}" = true ]; then
  echo "[DRY-RUN] would run: ${KUBECTL} wait pods -n "${NS}" --for condition=Ready --all --timeout=${WAIT_SECONDS}s"
else
  if ! ${KUBECTL} wait pods -n "${NS}" --for condition=Ready --all --timeout="${WAIT_SECONDS}s"; then
    echo "Warning: not all pods reached Ready within ${WAIT_SECONDS}s" >&2
    echo "Current pod status:"
    ${KUBECTL} -n "${NS}" get pods -o wide || true
  fi
fi

echo "All done. Summary:"
${KUBECTL} -n "${NS}" get deploy,statefulset,daemonset,pod -o wide || true

exit 0