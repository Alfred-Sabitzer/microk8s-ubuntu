#!/usr/bin/env bash
set -euo pipefail

openbaospace="openbao"
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

echo "Creating policy for secretspace eso-test..."
cat <<EOF | ${kubectl} --namespace="${openbaospace}" exec -i openbao-0 -- bao policy write eso-test -
# SPDX-License-Identifier: MPL-2.0
# Source and License see: https://github.com/Alfred-Sabitzer/microk8s-ubuntu/tree/main/applications/keepassxc
# Created on 2026-07-17 16:00:33
path "secret/data/eso-test/*" {
  capabilities = ["read"]
}
EOF

echo "Configuring role for secretspace eso-test..."
${kubectl} --namespace=${openbaospace} exec openbao-0 -- bao write auth/kubernetes/role/eso-test-role \
    bound_service_account_names=eso-test-sa \
    bound_service_account_namespaces=eso-test \
    audience="https://kubernetes.default.svc" \
    policies=eso-test \
    ttl=20m

echo "Activating secrets engine and creating secret for secretspace eso-test"
${kubectl} --namespace=${openbaospace} exec -i openbao-0 -- bao kv delete -mount=secret eso-test || true
echo "Create secret for secretspace eso-test"
${kubectl} --namespace="${openbaospace}" exec -i openbao-0 -- bao kv delete secret/eso-test/external-k8ssecret || true
${kubectl} --namespace="${openbaospace}" exec -i openbao-0 -- bao kv put secret/eso-test/external-k8ssecret  username="$(echo 'ZXh0ZXJuYWw=' | base64 --decode)" password="$(echo 'VU55YTU3NHVzWWF0VzlzclEzblhvelhMVFdNWWNGeDI5Q3lnM2taOQ==' | base64 --decode)" url="$(echo 'aHR0cHM6Ly9zbGFpbnRlLmF0' | base64 --decode)" notes="$(echo 'VGVzdCBmb3Igc3RhbmRhcmQgZXh0ZXJuYWwtazhzc2VjcmV0' | base64 --decode)"
${kubectl} --namespace="${openbaospace}" exec -i openbao-0 -- bao kv delete secret/eso-test/external-another-secret || true
${kubectl} --namespace="${openbaospace}" exec -i openbao-0 -- bao kv put secret/eso-test/external-another-secret  username="$(echo 'bXlVc2VyTmFtZQ==' | base64 --decode)" password="$(echo 'eEVVcmUldnNqJmYkcyNuMmBNJjVVenVNaXR5NWViWGtGJn5ZMnR+Zg==' | base64 --decode)" url="$(echo 'aHR0cHM6Ly90aGlzLWlzLW15LWV4dGVybmFsLXNlY3JldC5hdA==' | base64 --decode)" notes="$(echo 'VGVzdCBmb3IgYW4gYWRkaXRpb25hbCBleHRlcm5hbCBzZWNyZXQ=' | base64 --decode)"
