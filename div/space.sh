#!/usr/bin/env bash
#
# Show filesystem and top-level directory disk usage.

set -Eeuo pipefail

usage() {
    cat <<EOF
Usage: $0 [path]

Options:
  -h, --help    Show this help

The default path is /.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi
[[ $# -le 1 ]] || { usage >&2; exit 2; }

PATH_TO_CHECK=${1:-/}
[[ -d "$PATH_TO_CHECK" ]] || {
    echo "ERROR: Not a directory: $PATH_TO_CHECK" >&2
    exit 2
}

df -h

if [[ $EUID -eq 0 ]]; then
    DU=(du)
elif command -v sudo >/dev/null 2>&1; then
    DU=(sudo -A du)
else
    DU=(du)
fi

"${DU[@]}" -xhd1 "$PATH_TO_CHECK" 2>/dev/null | sort -hr
