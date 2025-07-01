#!/bin/bash
############################################################################################
#
# Configure Settings for OpenBao
#
# https://github.com/openbao/openbao-${my_namespace}-provider/tree/main/test/bats
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail

indir="$(dirname "$0")"
my_namespace="openbao"
CONFIGS="$indir/configs"

# Login????
kubectl --namespace=${my_namespace} exec -i openbao-0 -- bao login -

# 1. a) Openbao policies
cat $CONFIGS/openbao-policy-db.hcl | kubectl --namespace=${my_namespace} exec -i openbao-0 -- bao policy write db-policy -
cat $CONFIGS/openbao-policy-kv.hcl | kubectl --namespace=${my_namespace} exec -i openbao-0 -- bao policy write kv-policy -
cat $CONFIGS/openbao-policy-pki.hcl | kubectl --namespace=${my_namespace} exec -i openbao-0 -- bao policy write pki-policy -
cat $CONFIGS/openbao-policy-kv-custom-audience.hcl | kubectl --namespace=${my_namespace} exec -i openbao-0 -- bao policy write kv-custom-audience-policy -

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

# Configure roles
kubectl --namespace=${my_namespace} exec openbao-0 -- bao write auth/kubernetes/role/db-role \
    bound_service_account_names=nginx-db \
    bound_service_account_namespaces=test \
    audience=openbao \
    policies=db-policy \
    ttl=20m

kubectl --namespace=${my_namespace} exec openbao-0 -- bao write auth/kubernetes/role/kv-role \
    bound_service_account_names=nginx-kv \
    bound_service_account_namespaces=test \
    audience=openbao \
    policies=kv-policy \
    ttl=20m

kubectl --namespace=${my_namespace} exec openbao-0 -- bao write auth/kubernetes/role/kv-custom-audience-role \
    audience=custom-audience \
    bound_service_account_names=nginx-kv-custom-audience \
    bound_service_account_namespaces=test \
    policies=kv-custom-audience-policy \
    ttl=20m

kubectl --namespace=${my_namespace} exec openbao-0 -- bao write auth/kubernetes/role/pki-role \
    bound_service_account_names=nginx-pki \
    bound_service_account_namespaces=test \
    audience=openbao \
    policies=pki-policy \
    ttl=20m

kubectl --namespace=${my_namespace} exec openbao-0 -- bao write auth/kubernetes/role/all-role \
    bound_service_account_names=nginx-all \
    bound_service_account_namespaces=test \
    audience=openbao \
    policies=db-policy,kv-policy,pki-policy \
    ttl=20m

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

 kubectl --namespace=${my_namespace} exec openbao-0 -- bao write auth/jwt/role/jwt-kv-role \
     role_type="jwt" \
     bound_audiences="openbao" \
     user_claim="sub" \
     bound_subject="system:serviceaccount:test:nginx-kv" \
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
####


# 1. d) Setup kv secrets in Openbao.
kubectl --namespace=${my_namespace} exec openbao-0 -- bao secrets enable -path=secret -version=2 kv
kubectl --namespace=${my_namespace} exec openbao-0 -- bao kv put secret/kv1 bar1=hello1
kubectl --namespace=${my_namespace} exec openbao-0 -- bao kv put secret/kv2 bar2=hello2
kubectl --namespace=${my_namespace} exec openbao-0 -- bao kv put secret/kv-sync1 bar1=hello-sync1
kubectl --namespace=${my_namespace} exec openbao-0 -- bao kv put secret/kv-sync2 bar2=hello-sync2
kubectl --namespace=${my_namespace} exec openbao-0 -- bao kv put secret/kv-sync3 bar3=aGVsbG8tc3luYzM=
kubectl --namespace=${my_namespace} exec openbao-0 -- bao kv put secret/kv-custom-audience bar=hello-custom-audience

# 2. Create shared k8s resources.
kubectl create namespace test
kubectl --namespace=test apply -f $CONFIGS/openbao-all-secretproviderclass.yaml
kubectl --namespace=test apply -f $CONFIGS/openbao-db-secretproviderclass.yaml
kubectl --namespace=test apply -f $CONFIGS/openbao-kv-custom-audience-secretproviderclass.yaml
kubectl --namespace=test apply -f $CONFIGS/openbao-kv-namespace-secretproviderclass.yaml
kubectl --namespace=test apply -f $CONFIGS/openbao-kv-secretproviderclass.yaml
kubectl --namespace=test apply -f $CONFIGS/openbao-kv-secretproviderclass-jwt-auth.yaml
kubectl --namespace=test apply -f $CONFIGS/openbao-kv-sync-secretproviderclass.yaml
kubectl --namespace=test apply -f $CONFIGS/openbao-kv-sync-multiple-secretproviderclass.yaml
kubectl --namespace=test apply -f $CONFIGS/openbao-pki-secretproviderclass.yaml


# 3. Create test pods.


cat <<EOF | kubectl --namespace=${my_namespace} exec -i openbao-0 -- bao policy write alfred-policy -

path "secret/data/*" {
  capabilities = ["read"]
}
EOF

kubectl --namespace=${my_namespace} exec openbao-0 -- bao secrets enable -path=secret -version=2 kv
kubectl --namespace=${my_namespace} exec openbao-0 -- bao write auth/kubernetes/role/alfred-role \
    bound_service_account_names=openbaotest-sa \
    bound_service_account_namespaces=test \
    audience="https://kubernetes.default.svc" \
    policies=alfred-policy \
    ttl=20m

 kubectl --namespace=${my_namespace} exec openbao-0 -- bao write auth/jwt/role/jwt-alfred-role \
     role_type="jwt" \
     bound_audiences="https://kubernetes.default.svc" \
     user_claim="sub" \
     bound_subject="system:serviceaccount:test:openbaotest-sa" \
     policies="alfred-policy" \
     ttl="1h"

kubectl --namespace=openbao exec openbao-0 -- bao kv put secret/sabitzer alfred=sabitzer
kubectl --namespace=openbao exec openbao-0 -- bao kv get secret/sabitzer




kubectl apply -f alfred.yaml



---------------------------------------

MountVolume.SetUp failed for volume "secrets-store-inline" : 
rpc error: code = Unknown desc = failed to mount secrets store objects for pod test/openbaotest-5ff9b7649-9mfm4, 
err: rpc error: code = Unknown desc = error making mount request: couldn't read secret "alfred": failed to login: 
Error making API request. URL: POST http://%!F(MISSING)var%!F(MISSING)run%!F(MISSING)vault%!F(MISSING)agent.sock/v1/auth/kubernetes/login Code: 403. 
Errors: * invalid audience (aud) claim: audience claim does not match any expected audience



echo '{"apiVersion": "authentication.k8s.io/v1", "kind": "TokenRequest"}' \
  | kubectl create -f- --raw /api/v1/namespaces/test/serviceaccounts/default/token \
  | jq -r '.status.token' \
  | cut -d . -f2 \
  | base64 -D