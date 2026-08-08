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

sudo microk8s kubectl apply -f - <<EOF
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
  commonName: ${CN}
  duration: $(( DAYS * 24 ))h
  renewBefore: 360h
  privateKey:
    algorithm: RSA
    encoding: PKCS1
    size: 4096
    rotationPolicy: Always
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

for field in ca.crt tls.crt tls.key; do
  sudo microk8s kubectl get secret -n "$NAMESPACE" "$secret_name" -o jsonpath="{.data.${field}}" | base64 -d > "$outdir/$field"
done

sudo microk8s kubectl get secret -n cert-manager k8s-root-ca-secret -o jsonpath="{.data.ca\.crt}" | base64 -d > "$outdir/root.crt"

cat "$outdir/ca.crt" "$outdir/root.crt" > "$outdir/ca-bundle.crt"

openssl pkcs12 -export \
  -inkey "$outdir/tls.key" \
  -in "$outdir/tls.crt" \
  -certfile "$outdir/root.crt" \
  -out "$outdir/tls.p12" \
  -passout pass:"${PASSWORD}"

echo "${secret_name} certificate extracted to $outdir."
