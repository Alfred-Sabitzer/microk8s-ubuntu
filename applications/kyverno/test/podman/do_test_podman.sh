#!/usr/bin/env bash
############################################################################################
#
# Build and push a signed and unsigned dummy image to Harbor for Kyverno policy testing.
#
# Prerequisites:
#   - A working podman installation
#   - Access to a Harbor registry with HARBOR_USER/HARBOR_PASSWORD set
#   - The cluster already contains the "harbor-cosign" secret in the project namespace
#
# Usage:
#   HARBOR_USER="..." HARBOR_PASSWORD="..." ./do_test_podman.sh
############################################################################################
set -Eeuo pipefail

: "${HARBOR_USER:?Set HARBOR_USER before running this script}"
: "${HARBOR_PASSWORD:?Set HARBOR_PASSWORD before running this script}"

build="${build:-podman}"
tag="${tag:-$(date +%Y%m%d)}"
project="${project:-kyverno-test}"
image="${image:-dummy}"
HARBOR_LINK="${HARBOR_LINK:-harbor.test.slainte.at}"

if ! command -v "${build}" >/dev/null 2>&1; then
  printf 'Error: %s is not installed or not available in PATH.\n' "${build}" >&2
  exit 1
fi

if ! command -v cosign >/dev/null 2>&1; then
  printf 'Error: cosign is not installed or not available in PATH.\n' >&2
  exit 1
fi

printf 'Logging in to Harbor at %s...\n' "${HARBOR_LINK}"
"${build}" login "${HARBOR_LINK}" -u "${HARBOR_USER}" -p "${HARBOR_PASSWORD}"

printf 'Building %s/%s/%s:%s...\n' "${HARBOR_LINK}" "${project}" "${image}" "${tag}"
"${build}" build --network=host --no-cache --force-rm . -t "${HARBOR_LINK}/${project}/${image}:${tag}" -f dockerfile

digest=$("${build}" push "${HARBOR_LINK}/${project}/${image}:${tag}" --digestfile=/dev/stdout 2>/dev/null | tail -n 1)
if [[ -z "${digest}" ]]; then
  printf 'Error: failed to determine the pushed image digest.\n' >&2
  exit 1
fi

script_name="${build}_${project}_${image}_${tag}.sh"
cat <<EOF > "${script_name}"
#!/usr/bin/env bash
############################################################################################
#
# This script signs the image ${HARBOR_LINK}/${project}/${image}:${tag}
#
############################################################################################
set -Eeuo pipefail

# This helper script signs the image with cosign and verifies it with the public key stored in the
# cluster secret referenced by the test namespace.

HARBOR_LINK="${HARBOR_LINK}"
build="${build}"
tag="${tag}"
project="${project}"
image="${image}"
digest="${digest}"

if ! command -v cosign >/dev/null 2>&1; then
  printf 'Error: cosign is not installed or not available in PATH.\n' >&2
  exit 1
fi

kubectl_cmd="sudo microk8s kubectl"

export HARBOR_LINK="\$(\${kubectl_cmd} get services -n harbor harbor -o jsonpath='{.spec.clusterIP}')"
export COSIGN_USER="\$(\${kubectl_cmd} get secrets -n \${project} harbor-cosign -o jsonpath='{.data.username}' | base64 -d)"
export HARBOR_PASSWORD="\$(\${kubectl_cmd} get secrets -n \${project} harbor-cosign -o jsonpath='{.data.password}' | base64 -d)"
export COSIGN_PASSWORD="\$(\${kubectl_cmd} get secrets -n \${project} harbor-cosign -o jsonpath='{.data.cosign\\.password}' | base64 -d)"
export COSIGN_PRIVATE_KEY="\$(\${kubectl_cmd} get secrets -n \${project} harbor-cosign -o jsonpath='{.data.cosign\\.key}' | base64 -d)"
export COSIGN_PUBLIC_KEY="\$(\${kubectl_cmd} get secrets -n \${project} harbor-cosign -o jsonpath='{.data.cosign\\.pub}' | base64 -d)"
export DOCKER_CONFIG="\$(mktemp -d)"
trap 'rm -rf "\${DOCKER_CONFIG}"' EXIT

cosign login "\${HARBOR_LINK}" --username="\${COSIGN_USER}" --password="\${HARBOR_PASSWORD}"
cosign sign --key <(printf '%s' "\${COSIGN_PRIVATE_KEY}") --allow-insecure-registry "\${HARBOR_LINK}/\${project}/\${image}@\${digest}"
cosign verify --key <(printf '%s' "\${COSIGN_PUBLIC_KEY}") --allow-insecure-registry "\${HARBOR_LINK}/\${project}/\${image}@\${digest}"
EOF
chmod 755 "${script_name}"

env_name="${build}_${project}_${image}_${tag}.env"
cat <<EOF > "${env_name}"
############################################################################################
#
# This env file contains the values needed to deploy the image ${HARBOR_LINK}/${project}/${image}:${tag}
#
############################################################################################
export HARBOR_LINK="${HARBOR_LINK}"
export build="${build}"
export tag="${tag}"
export project="${project}"
export image="${image}"
export digest="${digest}"
EOF

printf '\nGenerated:\n'
printf '  - %s\n' "${script_name}"
printf '  - %s\n' "${env_name}"

printf '\nCreating an unsigned test image variant...\n'
unsigned_tag="unsigned-$(date +%Y%m%d)"
unsigned_image="dummy-unsigned"
"${build}" build --network=host --no-cache --force-rm . -t "${HARBOR_LINK}/${project}/${unsigned_image}:${unsigned_tag}" -f dockerfile
unsigned_digest=$("${build}" push "${HARBOR_LINK}/${project}/${unsigned_image}:${unsigned_tag}" --digestfile=/dev/stdout 2>/dev/null | tail -n 1)
if [[ -z "${unsigned_digest}" ]]; then
  printf 'Error: failed to determine the unsigned image digest.\n' >&2
  exit 1
fi

printf '\nUnsigned image digest: %s\n' "${unsigned_digest}"

