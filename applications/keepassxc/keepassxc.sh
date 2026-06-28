#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${VENV_DIR:-${SCRIPT_DIR}/.venv}"
PYTHON_BIN="${PYTHON_BIN:-${VENV_DIR}/bin/python}"

if [[ ! -x "${PYTHON_BIN}" ]]; then
  echo "Creating Python virtual environment in ${VENV_DIR}" >&2
  python3 -m venv "${VENV_DIR}"
fi

"${PYTHON_BIN}" -m pip install --upgrade pip >/dev/null
"${PYTHON_BIN}" -m pip install pykeepass pyyaml hvac ruamel.yaml >/dev/null

cat <<EOF
Virtual environment ready. Run the exporter with a command such as:

${PYTHON_BIN} keepass_to_eso_openbao.py \
  --kdbx ./python.kdbx \
  --password "your_database_password" \
  --outdir ./secrets \
  --mount kv \
  --prefix k8s
EOF
