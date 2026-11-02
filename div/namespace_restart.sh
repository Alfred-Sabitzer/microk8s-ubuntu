#!/usr/bin/env bash
################################################################################
#
# Restart all workloads in a Kubernetes namespace.
#
# Supported resources:
#   - Deployments
#   - StatefulSets
#   - DaemonSets
#
# Features:
#   - Dry-run mode
#   - Interactive confirmation
#   - Optional standalone pod deletion
#   - Rollout status verification
#   - Error collection
#
# Usage:
#   ./restart_namespace.sh
#   ./restart_namespace.sh observability
#   ./restart_namespace.sh observability --dry-run
#   ./restart_namespace.sh observability --yes
#   ./restart_namespace.sh observability --wait 600
#   ./restart_namespace.sh observability --delete-standalone-pods
#
# Environment:
#   KUBECTL_BIN       kubectl executable (default: auto-detect)
#   WAIT_SECONDS      Rollout timeout (default: 300)
#
################################################################################

set -Eeuo pipefail

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

NS="observability"
WAIT_SECONDS="${WAIT_SECONDS:-300}"

DRY_RUN=false
ASSUME_YES=false
DELETE_STANDALONE_PODS=false

ERRORS=0

# ------------------------------------------------------------------------------
# Kubernetes CLI
# ------------------------------------------------------------------------------

if [[ -n "${KUBECTL_BIN:-}" ]]; then

    command -v "$KUBECTL_BIN" >/dev/null 2>&1 \
        || { echo "ERROR: kubectl executable not found: $KUBECTL_BIN" >&2; exit 1; }

    KUBECTL=("$KUBECTL_BIN")

elif command -v microk8s >/dev/null 2>&1 && command -v sudo >/dev/null 2>&1; then

    KUBECTL=(sudo microk8s kubectl)

elif command -v kubectl >/dev/null 2>&1; then

    KUBECTL=(kubectl)

else

    echo "ERROR: Neither MicroK8s nor kubectl found." >&2
    exit 1

fi

# ------------------------------------------------------------------------------
# Functions
# ------------------------------------------------------------------------------

usage() {
    cat <<EOF
Usage: $0 [namespace] [options]

Options:
  --wait <seconds>           Rollout timeout (default: ${WAIT_SECONDS})
  --dry-run                  Show actions without executing
  --yes                      Skip confirmation
  --delete-standalone-pods   Delete pods without ownerReferences
  -h, --help                 Show this help

Environment:
  KUBECTL_BIN                kubectl executable
  WAIT_SECONDS               Default rollout timeout

Examples:
  $0
  $0 observability
  $0 observability --dry-run
  $0 observability --wait 600
  $0 observability --yes
  $0 observability --delete-standalone-pods
EOF
}

die() {
    echo "ERROR: $*" >&2
    exit 1
}

log() {
    echo
    echo "========== $* =========="
}

run() {
    if [[ "$DRY_RUN" == true ]]; then
        printf '[DRY-RUN]'
        printf ' %q' "$@"
        echo
        return 0
    fi

    "$@"
}

valid_integer() {
    [[ "$1" =~ ^[1-9][0-9]*$ ]]
}

# ------------------------------------------------------------------------------
# Argument parsing
# ------------------------------------------------------------------------------

NAMESPACE_SET=false

while (($#)); do

    case "$1" in

        --wait)
            (($# >= 2)) || die "--wait requires a value"
            WAIT_SECONDS="$2"
            shift 2
            ;;

        --dry-run)
            DRY_RUN=true
            shift
            ;;

        --yes)
            ASSUME_YES=true
            shift
            ;;

        --delete-standalone-pods)
            DELETE_STANDALONE_PODS=true
            shift
            ;;

        -h|--help)
            usage
            exit 0
            ;;

        -*)
            die "Unknown option: $1"
            ;;

        *)
            [[ "$NAMESPACE_SET" == false ]] \
                || die "Only one namespace may be specified"

            NS="$1"
            NAMESPACE_SET=true
            shift
            ;;

    esac

done

valid_integer "$WAIT_SECONDS" \
    || die "WAIT_SECONDS must be a positive integer"

[[ "$NS" =~ ^[a-z0-9]([-a-z0-9]*[a-z0-9])?$ ]] \
    || die "Invalid Kubernetes namespace: $NS"

# ------------------------------------------------------------------------------
# Namespace validation
# ------------------------------------------------------------------------------

log "Configuration"

echo "Namespace              : $NS"
echo "Kubectl                : ${KUBECTL[*]}"
echo "Wait seconds           : $WAIT_SECONDS"
echo "Dry-run                : $DRY_RUN"
echo "Delete standalone pods : $DELETE_STANDALONE_PODS"

"${KUBECTL[@]}" get namespace "$NS" >/dev/null \
    || die "Namespace does not exist or is inaccessible: $NS"

# ------------------------------------------------------------------------------
# Confirmation
# ------------------------------------------------------------------------------

if [[ "$DRY_RUN" == false && "$ASSUME_YES" == false ]]; then

    echo
    read -r -p "Restart workloads in namespace '$NS'? [y/N] " answer

    case "$answer" in
        [Yy]|[Yy][Ee][Ss]) ;;
        *)
            echo "Aborted."
            exit 0
            ;;
    esac

fi

# ------------------------------------------------------------------------------
# Restart workloads
# ------------------------------------------------------------------------------

restart_workloads() {

    local kind="$1"
    local item
    local names

    log "Restarting $kind"

    names=$("${KUBECTL[@]}" get "$kind" \
        -n "$NS" \
        -o name) || {
            echo "ERROR: Cannot list $kind" >&2
            ((ERRORS+=1))
            return
        }

    if [[ -z "$names" ]]; then
        echo "No $kind found."
        return
    fi

    while IFS= read -r item; do

        [[ -z "$item" ]] && continue

        echo "Restarting $item"

        if ! run "${KUBECTL[@]}" rollout restart \
            "$item" -n "$NS"; then

            echo "ERROR: Restart failed: $item" >&2
            ((ERRORS+=1))
            continue

        fi

        if [[ "$DRY_RUN" == false ]]; then

            echo "Waiting for rollout: $item"

            if ! "${KUBECTL[@]}" rollout status \
                "$item" \
                -n "$NS" \
                --timeout="${WAIT_SECONDS}s"; then

                echo "ERROR: Rollout failed or timed out: $item" >&2
                ((ERRORS+=1))

            fi

        fi

    done <<< "$names"

}

# ------------------------------------------------------------------------------
# Restart Deployments
# ------------------------------------------------------------------------------

restart_workloads deployment

# ------------------------------------------------------------------------------
# Restart StatefulSets
# ------------------------------------------------------------------------------

restart_workloads statefulset

# ------------------------------------------------------------------------------
# Restart DaemonSets
# ------------------------------------------------------------------------------

restart_workloads daemonset

# ------------------------------------------------------------------------------
# Delete standalone pods (optional)
# ------------------------------------------------------------------------------

if [[ "$DELETE_STANDALONE_PODS" == true ]]; then

    log "Standalone pods"

    command -v jq >/dev/null 2>&1 \
        || die "jq is required for standalone pod detection"

    pods=$("${KUBECTL[@]}" get pods \
        -n "$NS" \
        -o json) || die "Cannot retrieve pods"

    mapfile -t standalone_pods < <(
        jq -r '
            .items[]
            | select((.metadata.ownerReferences // []) | length == 0)
            | .metadata.name
        ' <<< "$pods"
    )

    if ((${#standalone_pods[@]} == 0)); then

        echo "No standalone pods found."

    else

        for pod in "${standalone_pods[@]}"; do

            echo "Deleting standalone pod: $pod"

            if ! run "${KUBECTL[@]}" delete pod "$pod" \
                -n "$NS" \
                --grace-period=30 \
                --wait=true \
                --timeout=120s; then

                echo "ERROR: Could not delete pod $pod" >&2
                ((ERRORS+=1))

            fi

        done

    fi

fi

# ------------------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------------------

log "Final resource status"

"${KUBECTL[@]}" get \
    deployments,statefulsets,daemonsets,pods \
    -n "$NS" \
    -o wide || {
        echo "WARNING: Could not retrieve final resource status." >&2
        ((ERRORS+=1))
    }

# ------------------------------------------------------------------------------
# Result
# ------------------------------------------------------------------------------

log "Result"

if [[ "$DRY_RUN" == true ]]; then

    echo "Dry-run completed. No changes were made."

elif ((ERRORS > 0)); then

    echo "Completed with $ERRORS error(s)." >&2
    exit 1

else

    echo "All workloads restarted successfully."

fi

exit 0