#!/usr/bin/env bash
#
# Export every Kubernetes CustomResourceDefinition to a separate YAML file.

set -Eeuo pipefail

usage() {
    cat <<EOF
Usage: $0 [output-directory]

Options:
  -h, --help    Show this help

Environment:
  KUBECTL_BIN   kubectl executable or command name (default: auto-detect)

Examples:
  $0
  $0 ./exports
EOF
}

die() {
    echo "ERROR: $*" >&2
    exit 1
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi
[[ $# -le 1 ]] || { usage >&2; exit 2; }

OUTPUT_DIR="${1:-.}"

if [[ -n "${KUBECTL_BIN:-}" ]]; then
    read -r -a KUBECTL <<<"$KUBECTL_BIN"
elif command -v microk8s >/dev/null 2>&1 && command -v sudo >/dev/null 2>&1; then
    KUBECTL=(sudo microk8s kubectl)
elif command -v kubectl >/dev/null 2>&1; then
    KUBECTL=(kubectl)
else
    die "Neither MicroK8s nor kubectl was found"
fi

if [[ -e "$OUTPUT_DIR" && ! -d "$OUTPUT_DIR" ]]; then
    die "Output path is not a directory: $OUTPUT_DIR"
fi
mkdir -p "$OUTPUT_DIR"

mapfile -t CRDS < <(
    "${KUBECTL[@]}" get customresourcedefinitions.apiextensions.k8s.io \
        -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'
) || die "Could not list custom resource definitions"

if ((${#CRDS[@]} == 0)); then
    echo "No custom resource definitions found."
    exit 0
fi

echo "Exporting ${#CRDS[@]} custom resource definitions to ${OUTPUT_DIR}"
for name in "${CRDS[@]}"; do
    [[ -n "$name" ]] || continue
    output="${OUTPUT_DIR}/${name}.yaml"
    echo "  $name"
    "${KUBECTL[@]}" get customresourcedefinition "$name" -o yaml >"$output" \
        || die "Could not export $name"
done

