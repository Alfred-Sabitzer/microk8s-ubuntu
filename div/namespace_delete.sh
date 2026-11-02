#!/usr/bin/env bash
################################################################################
#
# Force cleanup of a stuck Kubernetes namespace.
#
# Default: Dry run (no changes).
#
# Usage:
#   ./namespace_delete.sh test
#   ./namespace_delete.sh test --force
#
################################################################################

set -Eeuo pipefail

KUBECTL=(sudo microk8s kubectl)

NAMESPACE="${1:-test}"
FORCE="${2:-}"

usage() {
    cat <<EOF
Usage: $0 [namespace] [--force]

Options:
  --force    Remove finalizers and force namespace finalization.
             Without this option, only a dry run is performed.

Examples:
  $0 test
  $0 test --force
EOF
}

die() {
    echo "❌ ERROR: $*" >&2
    exit 1
}

trap 'rc=$?; echo "❌ Script failed with exit code $rc" >&2' ERR

# ------------------------------------------------------------------------------
# Validate arguments
# ------------------------------------------------------------------------------

if [[ "$NAMESPACE" == "--help" || "$NAMESPACE" == "-h" ]]; then
    usage
    exit 0
fi

if [[ $# -gt 2 ]]; then
    usage
    exit 1
fi

if [[ -n "$FORCE" && "$FORCE" != "--force" ]]; then
    die "Unknown option: $FORCE"
fi

[[ "$NAMESPACE" =~ ^[a-z0-9]([-a-z0-9]*[a-z0-9])?$ ]] \
    || die "Invalid namespace name: $NAMESPACE"

case "$NAMESPACE" in
    default|kube-system|kube-public|kube-node-lease)
        die "Refusing to clean protected namespace: $NAMESPACE"
        ;;
esac

command -v jq >/dev/null 2>&1 || die "jq is required"

"${KUBECTL[@]}" get namespace "$NAMESPACE" >/dev/null \
    || die "Namespace does not exist: $NAMESPACE"

PHASE=$("${KUBECTL[@]}" get namespace "$NAMESPACE" \
    -o jsonpath='{.status.phase}')

echo "Namespace : $NAMESPACE"
echo "Phase     : $PHASE"
echo "Mode      : ${FORCE:-DRY-RUN}"
echo

if [[ "$FORCE" == "--force" ]]; then

    [[ "$PHASE" == "Terminating" ]] \
        || die "Namespace is not terminating. Refusing force cleanup."

    echo "⚠️ WARNING: This will remove finalizers from ALL namespaced resources!"
    echo

    read -r -p "Type '$NAMESPACE' to confirm: " CONFIRM

    [[ "$CONFIRM" == "$NAMESPACE" ]] || die "Operation cancelled"

fi

# ------------------------------------------------------------------------------
# Discover namespaced API resources
# ------------------------------------------------------------------------------

echo "Discovering namespaced API resources..."

RESOURCE_TYPES=$("${KUBECTL[@]}" api-resources \
    --verbs=list \
    --namespaced \
    -o name) || die "Cannot discover API resources"

mapfile -t RESOURCES < <(printf '%s\n' "$RESOURCE_TYPES" | sort -u)

echo "Found ${#RESOURCES[@]} resource types."
echo

# ------------------------------------------------------------------------------
# Process resources
# ------------------------------------------------------------------------------

for API in "${RESOURCES[@]}"; do

    echo "Checking $API..."

    ITEMS=$("${KUBECTL[@]}" get "$API" \
        -n "$NAMESPACE" \
        -o name \
        --ignore-not-found) || die "Cannot list $API"

    [[ -z "$ITEMS" ]] && continue

    while IFS= read -r ITEM; do

        [[ -z "$ITEM" ]] && continue

        echo "  Found: $ITEM"

        if [[ "$FORCE" == "--force" ]]; then

            echo "  Removing finalizers: $ITEM"

            "${KUBECTL[@]}" patch "$ITEM" \
                -n "$NAMESPACE" \
                --type=merge \
                -p '{"metadata":{"finalizers":[]}}'

        else
            echo "  DRY-RUN: Would remove finalizers from $ITEM"
        fi

    done <<< "$ITEMS"

done

# ------------------------------------------------------------------------------
# Remove namespace finalizers
# ------------------------------------------------------------------------------

echo
echo "========== Namespace finalization =========="

if [[ "$FORCE" == "--force" ]]; then

    echo "Removing namespace finalizers..."

    "${KUBECTL[@]}" get namespace "$NAMESPACE" -o json \
        | jq '.metadata.finalizers = [] | .spec.finalizers = []' \
        | "${KUBECTL[@]}" replace --raw \
            "/api/v1/namespaces/${NAMESPACE}/finalize" -f -

    echo "Deleting namespace..."

    "${KUBECTL[@]}" delete namespace "$NAMESPACE" \
        --ignore-not-found=true

    echo "✅ Namespace cleanup completed."

else

    echo "DRY-RUN: No changes were made."
    echo
    echo "To execute the cleanup:"
    echo "  $0 $NAMESPACE --force"

fi
