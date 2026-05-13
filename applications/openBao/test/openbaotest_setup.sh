#!/bin/bash
############################################################################################
#
# Assumption: OpenBao is already installed and running in the cluster, and the openbao-0 pod is available.
# This script will:
# 1. Create a policy that allows read access to the "test/*" path.
# 2. Enable the KV secrets engine at the "test" path and create a secret
# 3. Enable the Kubernetes auth method and configure it to use the service account token.
#
# https://github.com/openbao/openbao-csi-provider/tree/main/test/bats
#
# Structure:
#
# One secret-path per Namespace, and one Role per Namespace. This allows for better organization and management of secrets.
# One Policy per Role, and one Role per Service Account. This allows for better management and auditing of permissions.
# One Service Account per Role. This allows for better isolation and security.
#
# Note: This script is intended for testing purposes and should not be used in production environments without proper security considerations.
############################################################################################
shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
shopt -o -s nounset #-No Variables without definition
set -euo pipefail

openbaospace="openbao"
secretspace=${1:-openbaotest}
kubectl="sudo microk8s kubectl"

if [ -z "${OPENBAO_ROOT_TOKEN:-}" ]; then
  echo "Error: OPENBAO_ROOT_TOKEN must be set" >&2
  exit 1
fi

if ! ${kubectl} -n "${openbaospace}" get pod openbao-0 >/dev/null 2>&1; then
  echo "Error: OpenBao pod openbao-0 not found in namespace ${openbaospace}" >&2
  exit 1
fi

# Login
roottoken="${OPENBAO_ROOT_TOKEN}"
echo "${roottoken}" | ${kubectl} --namespace="${openbaospace}" exec -i openbao-0 -- bao login -

# Create Policy
echo "Creating policy for secretspace ${secretspace}..."
cat <<EOF | ${kubectl} --namespace="${openbaospace}" exec -i openbao-0 -- bao policy write "kv-${secretspace}" -
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0
# Created on $(date -u +"%Y-%m-%dT%H:%M:%SZ") by ${0}

path "secret/data/${secretspace}/*" {
  capabilities = ["read"]
}
EOF

# Configure roles
echo "Configuring role for secretspace ${secretspace}..."
${kubectl} --namespace=${openbaospace} exec openbao-0 -- bao write auth/kubernetes/role/${secretspace}-role \
    bound_service_account_names=${secretspace}-sa \
    bound_service_account_namespaces=${secretspace} \
    audience="https://kubernetes.default.svc" \
    policies=kv-${secretspace} \
    ttl=20m

# activate secrets engine and create secret
echo "Activating secrets engine and creating secret for secretspace ${secretspace}..."
${kubectl} --namespace="${openbaospace}" exec -i openbao-0 -- bao kv delete -mount=secret "${secretspace}" || true
${kubectl} --namespace="${openbaospace}" exec -i openbao-0 -- bao kv put secret/${secretspace}/my_secret alfred="alfred" sabitzer="sabitzer"
${kubectl} --namespace="${openbaospace}" exec -i openbao-0 -- bao kv get secret/${secretspace}/my_secret


############################################################################################