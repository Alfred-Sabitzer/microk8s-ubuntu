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
shopt -o -s errexit    #—Terminates the shell script if a command returns an error code.
# shopt -o -s xtrace #—Displays each command before it is executed.
shopt -o -s nounset #-No Variables without definition
set -euo pipefail

die() { echo "Error: $*" >&2; exit 1; }

openbaospace="openbao"
secretspace=${1:-openbaotest}
kubectl="sudo microk8s kubectl"

if [ -z "${OPENBAO_ROOT_TOKEN:-}" ]; then
  die "OPENBAO_ROOT_TOKEN must be set"
fi

if ! ${kubectl} -n "${openbaospace}" get pod openbao-0 >/dev/null 2>&1; then
  die "OpenBao pod openbao-0 not found in namespace ${openbaospace}"
fi

# Login
roottoken="${OPENBAO_ROOT_TOKEN}"
echo "${roottoken}" | ${kubectl} --namespace="${openbaospace}" exec -i openbao-0 -- bao login -

# activate secrets engine and create secret
${kubectl} --namespace="${openbaospace}" exec -i openbao-0 -- bao secrets enable -path=secret kv-v2 || true

# activate Kubernetes auth method
${kubectl} --namespace="${openbaospace}" exec -i openbao-0 -- bao auth enable kubernetes  || true
${kubectl} --namespace="${openbaospace}" exec -i openbao-0 -- bao auth list  || true

# configure Kubernetes auth method
${kubectl} --namespace="${openbaospace}" exec openbao-0 -- sh -c 'bao write auth/kubernetes/config \
    issuer="https://kubernetes.default.svc.cluster.local" \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"'
#    token_reviewer_jwt=@/var/run/secrets/kubernetes.io/serviceaccount/token'

############################################################################################