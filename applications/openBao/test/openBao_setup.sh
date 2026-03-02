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
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
shopt -o -s nounset #-No Variables without definition
set -euo pipefail

my_namespace=${1:-test}

# Create Policy
cat <<EOF | kubectl --namespace=${my_namespace} exec -i openbao-0 -- bao policy write kv-${my_namespace} -
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0
# Created on $(date -u +"%Y-%m-%dT%H:%M:%SZ") by ${0}

path "/secret/${my_namespace}/*" {
  capabilities = ["read"]
}
EOF

# activate secrets engine and create secret
kubectl --namespace=${my_namespace} exec -i openbao-0 -- bao secrets enable -path=${my_namespace} kv-v2
kubectl --namespace=${my_namespace} exec -i openbao-0 -- bao kv put /secret/${my_namespace} username="admin" password="super-secret-password"

# activate Kubernetes auth method
kubectl --namespace=${my_namespace} exec -i openbao-0 -- bao auth enable kubernetes
# configure Kubernetes auth method
kubectl --namespace=${my_namespace} exec openbao-0 -- sh -c 'bao write auth/kubernetes/config \
    issuer="https://kubernetes.default.svc.cluster.local" \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    token_reviewer_jwt=@/var/run/secrets/kubernetes.io/serviceaccount/token'

# Configure roles
kubectl --namespace=${my_namespace} exec openbao-0 -- bao write auth/kubernetes/role/${my_namespace}-role \
    bound_service_account_names=${my_namespace}-sa \
    bound_service_account_namespaces=${my_namespace} \
    audience="https://kubernetes.default.svc" \
    policies=kv-${my_namespace} \
    ttl=20m

############################################################################################