#!/usr/bin/env bash
############################################################################################
#
# This script signs the image harbor.test.slainte.at/kyverno-test/dummy:20261001
#
############################################################################################
set -Eeuo pipefail

# This helper script signs the image with cosign and verifies it with the public key stored in the
# cluster secret referenced by the test namespace.

HARBOR_LINK="harbor.test.slainte.at"
build="podman"
tag="20261001"
project="kyverno-test"
image="dummy"
digest="sha256:57565c078cabc055e833f6e03dd11a5d873e8dd800f5b2e10588d54f0b7f16be"

if ! command -v cosign >/dev/null 2>&1; then
  printf 'Error: cosign is not installed or not available in PATH.\n' >&2
  exit 1
fi

kubectl_cmd="sudo microk8s kubectl"

export HARBOR_LINK="$(${kubectl_cmd} get services -n harbor harbor -o jsonpath='{.spec.clusterIP}')"
export COSIGN_USER="$(${kubectl_cmd} get secrets -n ${project} harbor-cosign -o jsonpath='{.data.username}' | base64 -d)"
export HARBOR_PASSWORD="$(${kubectl_cmd} get secrets -n ${project} harbor-cosign -o jsonpath='{.data.password}' | base64 -d)"
export COSIGN_PASSWORD="$(${kubectl_cmd} get secrets -n ${project} harbor-cosign -o jsonpath='{.data.cosign\.password}' | base64 -d)"
export COSIGN_PRIVATE_KEY="$(${kubectl_cmd} get secrets -n ${project} harbor-cosign -o jsonpath='{.data.cosign\.key}' | base64 -d)"
export COSIGN_PUBLIC_KEY="$(${kubectl_cmd} get secrets -n ${project} harbor-cosign -o jsonpath='{.data.cosign\.pub}' | base64 -d)"
export DOCKER_CONFIG="$(mktemp -d)"
trap 'rm -rf "${DOCKER_CONFIG}"' EXIT

cosign login "${HARBOR_LINK}" --username="${COSIGN_USER}" --password="${HARBOR_PASSWORD}"
cosign sign --key <(printf '%s' "${COSIGN_PRIVATE_KEY}") --allow-insecure-registry "${HARBOR_LINK}/${project}/${image}@${digest}"
cosign verify --key <(printf '%s' "${COSIGN_PUBLIC_KEY}") --allow-insecure-registry "${HARBOR_LINK}/${project}/${image}@${digest}"

