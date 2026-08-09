#!/bin/bash
############################################################################################
#
# Script to create a client certificates
#
############################################################################################
#shopt -o -s errexit #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace  #—Displays each command before it is executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail

if [ $# -lt 1 ] || [ $# -gt 5 ]; then
  cat <<EOF
Usage: $0 EMAIL [COMMON_NAME] [PASSWORD] [DAYS] [NAMESPACE]

Create a cert-manager Certificate resource for a client certificate and export the generated secret.

Arguments:
  EMAIL        Email address for the client certificate.
  COMMON_NAME  Optional commonName for the certificate (default: email local-part).
  PASSWORD     Password for the resulting PKCS#12 file (default: changeit).
  DAYS         Certificate duration in days (default: 365).
  NAMESPACE    Kubernetes namespace for the Certificate resource (default: client-certificates).
EOF
  exit 1
fi

EMAIL="$1"
CN="${2:-${EMAIL%%@*}}"
PASSWORD="${3:-changeit}"
DAYS="${4:-365}"
NAMESPACE="${5:-client-certificates}"

secret_name=$(echo "$EMAIL" | tr '@.' '--')

outdir="$HOME/pki/$secret_name"
rm -rf "$outdir" || true
mkdir -p "$outdir"
kubectl delete secret -n "${NAMESPACE}" "${secret_name}" --ignore-not-found
kubectl delete certificate -n "${NAMESPACE}" "${secret_name}" --ignore-not-found
#
kubectl apply -f - <<EOF
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ${secret_name}
  namespace: ${NAMESPACE}
spec:
  secretName: ${secret_name}
  emailAddresses:
    - ${EMAIL}
  commonName: "${CN}"                         # CN (Max 64 chars)
  encodeUsagesInRequest:  true
  subject:
    organizations:
      - "Slainte"                               # O  (Max 64 chars)
    organizationalUnits:
      - "Information Technology"                # OU (Max 64 chars)
    countries:
      - "AT"                                    # C  (Exactly 2 chars ISO)
    provinces:
      - "Vienna"                                # ST (Max 128 chars)
    localities:
      - "Brigittenau"                           # L  (Max 128 chars)
  duration: $(( DAYS * 24 ))h
  renewBefore: 360h
  privateKey:
    algorithm: RSA
    encoding: PKCS1
    size: 4096
    rotationPolicy: Always
  keystores:
    jks:
      create: false
      password: "${PASSWORD}"
    pkcs12:
      create: true
      password: "${PASSWORD}"
      profile: Modern2023
  usages:
    - digital signature
    - key encipherment
    - client auth
    - email protection
  issuerRef:
    group: cert-manager.io
    kind: ClusterIssuer
    name: k8s-intermediate-issuer
---
EOF
#
kubectl wait --for=condition=Ready certificate/${secret_name} -n ${NAMESPACE} --timeout=120s || {
  echo "Error: Certificate ${secret_name} did not become ready in time."
  exit 1
}
#
kubectl get secret -n "${NAMESPACE}" "${secret_name}" -o jsonpath="{.data.ca\.crt}" | base64 -d > "$outdir/ca.crt"
kubectl get secret -n "${NAMESPACE}" "${secret_name}" -o jsonpath="{.data.tls\.crt}" | base64 -d > "$outdir/tls.crt"
kubectl get secret -n "${NAMESPACE}" "${secret_name}" -o jsonpath="{.data.tls\.key}" | base64 -d > "$outdir/tls.key"
kubectl get secret -n "${NAMESPACE}" "${secret_name}" -o jsonpath="{.data.keystore\.p12}" | base64 -d > "$outdir/tls-keystore.p12"
kubectl get secret -n "${NAMESPACE}" "${secret_name}" -o jsonpath="{.data.truststore\.p12}" | base64 -d > "$outdir/tls-truststore.p12"
#
echo "${secret_name} certificate extracted to $outdir."
