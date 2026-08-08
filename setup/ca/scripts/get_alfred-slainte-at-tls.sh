#!/bin/bash
############################################################################################
#
# Extract the specific client certificate from the cert-manager secret and save it to a file.
#
############################################################################################
#shopt -o -s errexit #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace  #—Displays each command before it is executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail

secret_name="${1:-alfred-slainte-at-tls}"
namespace="${2:-istio-system}"
password="${3:-changeit}"
outdir="${4:-$HOME/pki/${secret_name}}"

mkdir -p "$outdir"

kubectl get secret -n "$namespace" "$secret_name" >/dev/null 2>&1 || {
  echo "Error: secret '$secret_name' not found in namespace '$namespace'."
  exit 1
}

kubectl get secret -n "$namespace" "$secret_name" -o jsonpath="{.data.ca\.crt}" | base64 -d > "$outdir/ca.crt"
kubectl get secret -n "$namespace" "$secret_name" -o jsonpath="{.data.tls\.crt}" | base64 -d > "$outdir/tls.crt"
kubectl get secret -n "$namespace" "$secret_name" -o jsonpath="{.data.tls\.key}" | base64 -d > "$outdir/tls.key"

if kubectl get secret -n cert-manager k8s-root-ca-secret >/dev/null 2>&1; then
  kubectl get secret -n cert-manager k8s-root-ca-secret -o jsonpath="{.data.ca\.crt}" | base64 -d > "$outdir/root.crt"
  cat "$outdir/ca.crt" "$outdir/root.crt" > "$outdir/ca-bundle.crt"
fi

openssl pkcs12 -export \
  -inkey "$outdir/tls.key" \
  -in "$outdir/tls.crt" \
  -certfile "$outdir/root.crt" \
  -out "$outdir/tls.p12" \
  -passout pass:"${password}"

echo "Extracted certificate files to $outdir."
