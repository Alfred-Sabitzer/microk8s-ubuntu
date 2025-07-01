#!/bin/bash
############################################################################################
#
# Configure Settings for OpenBao
#
# https://github.com/openbao/openbao-csi-provider/tree/main/test/bats
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail

indir="$(dirname "$0")"
my_namespace="openbao"

# Login????
#$ foo=${string#"$prefix"}
#$ foo=${foo%"$suffix"}
mymap=$(kubectl get configmaps -n openbao openbao-unseal-config -o yaml)
key=${mymap#*root_token: }  
roottoken=$(echo $key | cut -d " " -f 1)

echo $roottoken | kubectl --namespace=${my_namespace} exec -i openbao-0 -- bao login -

# 1. a) Openbao policies
cat <<EOF | kubectl --namespace=${my_namespace} exec -i openbao-0 -- bao policy write db-policy -
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

path "database/creds/test-role" {
  capabilities = ["read"]
}
EOF

cat <<EOF | kubectl --namespace=${my_namespace} exec -i openbao-0 -- bao policy write kv-policy -
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

path "secret/*" {
  capabilities = ["read"]
}
EOF

cat <<EOF | kubectl --namespace=${my_namespace} exec -i openbao-0 -- bao policy write pki-policy -
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

path "pki/issue/slainte-dot-at" {
  capabilities = ["update"]
}
EOF

# 1. b) i) Setup kubernetes auth engine.
kubectl --namespace=${my_namespace} exec openbao-0 -- bao auth enable kubernetes

# Use local service account token as the reviewer JWT
# kubectl --namespace=${my_namespace} exec openbao-0 -- sh -c 'bao write auth/kubernetes/config \
#     kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
#     kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
#     token_reviewer_jwt=@/var/run/secrets/kubernetes.io/serviceaccount/token'
# See https://openbao.org/docs/auth/kubernetes/
kubectl --namespace=${my_namespace} exec openbao-0 -- sh -c 'bao write auth/kubernetes/config \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"'
kubectl --namespace=${my_namespace} exec openbao-0 -- bao read auth/kubernetes/config


# 1. b) ii) Setup JWT auth
# See https://openbao.org/docs/auth/jwt/oidc-providers/kubernetes/
kubectl delete clusterrolebinding oidc-reviewer --ignore-not-found=true || true
kubectl create clusterrolebinding oidc-reviewer  \
   --clusterrole=system:service-account-issuer-discovery \
   --group=system:unauthenticated

 kubectl --namespace=${my_namespace} exec openbao-0 -- bao auth enable jwt
   
 kubectl --namespace=${my_namespace} exec openbao-0 -- bao write auth/jwt/config \
     oidc_discovery_url=https://kubernetes.default.svc \
     oidc_discovery_ca_pem=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

# Configure roles
kubectl --namespace=${my_namespace} exec openbao-0 -- bao write auth/kubernetes/role/kv-role \
    bound_service_account_names=openbaotest-sa \
    bound_service_account_namespaces=test \
    audience="https://kubernetes.default.svc" \
    policies=kv-policy \
    ttl=20m

 kubectl --namespace=${my_namespace} exec openbao-0 -- bao write auth/jwt/role/jwt-kv-role \
     role_type="jwt" \
     bound_audiences="https://kubernetes.default.svc" \
     user_claim="sub" \
     bound_subject="system:serviceaccount:test:openbaotest-sa" \
     policies="kv-policy" \
     ttl="1h"

 
# 1. c) Setup pki secrets engine.
kubectl --namespace=${my_namespace} exec openbao-0 -- bao secrets enable pki
kubectl --namespace=${my_namespace} exec openbao-0 -- bao write -field=certificate pki/root/generate/internal \
    common_name="slainte.at"
kubectl --namespace=${my_namespace} exec openbao-0 -- bao write pki/config/urls \
    issuing_certificates="http://127.0.0.1:8200/v1/pki/ca"
kubectl --namespace=${my_namespace} exec openbao-0 -- bao write pki/roles/slainte-dot-at \
    allowed_domains="slainte.at" \
    allow_subdomains=true


# 1. d) Setup kv secrets in Openbao.
kubectl --namespace=${my_namespace} exec openbao-0 -- bao secrets enable -path=secret -version=2 kv

kubectl --namespace=openbao exec openbao-0 -- bao kv put secret/sabitzer alfred=sabitzer
kubectl --namespace=openbao exec openbao-0 -- bao kv get secret/sabitzer


# 2. Create shared k8s resources.

# 3. Create test pods.

kubectl apply -f "$indir/openbaotest.yaml"  
