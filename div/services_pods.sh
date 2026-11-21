#!/usr/bin/env bash
#
# List pods selected by every Service in one or all namespaces.

set -Eeuo pipefail

usage() {
    cat <<EOF
Usage: $0 [namespace]

Options:
  -A, --all-namespaces    Inspect Services in all namespaces (default)
  -n, --namespace NAME    Inspect Services in one namespace
  -h, --help              Show this help

Environment:
  KUBECTL_BIN             kubectl executable or command name (default: auto-detect)
EOF
}

die() {
    echo "ERROR: $*" >&2
    exit 1
}

NAMESPACE=""
while (($#)); do
    case "$1" in
        -A|--all-namespaces) NAMESPACE=""; shift ;;
        -n|--namespace)
            (($# >= 2)) || die "$1 requires a value"
            NAMESPACE=$2
            shift 2
            ;;
        -h|--help) usage; exit 0 ;;
        -*)
            die "Unknown option: $1"
            ;;
        *)
            [[ -z "$NAMESPACE" ]] || die "Only one namespace may be specified"
            NAMESPACE=$1
            shift
            ;;
    esac
done

if [[ -n "$NAMESPACE" && ! "$NAMESPACE" =~ ^[a-z0-9]([-a-z0-9]*[a-z0-9])?$ ]]; then
    die "Invalid Kubernetes namespace: $NAMESPACE"
fi

if [[ -n "${KUBECTL_BIN:-}" ]]; then
    read -r -a KUBECTL <<<"$KUBECTL_BIN"
elif command -v microk8s >/dev/null 2>&1 && command -v sudo >/dev/null 2>&1; then
    KUBECTL=(sudo microk8s kubectl)
elif command -v kubectl >/dev/null 2>&1; then
    KUBECTL=(kubectl)
else
    die "Neither MicroK8s nor kubectl was found"
fi

if [[ -n "$NAMESPACE" ]]; then
    namespaces=(-n "$NAMESPACE")
else
    namespaces=(--all-namespaces)
fi

mapfile -t SERVICES < <(
    "${KUBECTL[@]}" get services "${namespaces[@]}" \
        -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\n"}{end}'
) || die "Could not list Services"

for service in "${SERVICES[@]}"; do
    [[ -n "$service" ]] || continue
    namespace=${service%%$'\t'*}
    name=${service#*$'\t'}
    # shellcheck disable=SC2016
    mapfile -t SELECTORS < <(
        "${KUBECTL[@]}" get service "$name" -n "$namespace" \
            -o jsonpath='{range $key, $value := .spec.selector}{$key}{"="}{$value}{","}{end}'
    ) || die "Could not read selector for $namespace/$name"
    selector=${SELECTORS[0]:-}
    selector=${selector%,}

    echo
    echo "Service: $namespace/$name"
    if [[ -z "$selector" ]]; then
        echo "  No pod selector"
    else
        "${KUBECTL[@]}" get pods -n "$namespace" --selector="$selector"
    fi
done
