#!/bin/bash
################################################################################
#
# Create a client certificate for mutual TLS
#
# Usage:
#   ./client_certificate.sh [client_email] [host] [web_secret] [web_namespace]
#
# Examples:
#   ./client_certificate.sh
#   ./client_certificate.sh "alfred@slainte.at" "*.example.com" "k8s-selfsigned-ca-secret" "cert-manager"
#
# Prerequisites:
#   - kubectl/microk8s kubectl available and configured
#   - K8S_ENVIRONMENT environment variable set
#   - Target namespace with CA secret exists
#
# References:
#   - https://istio.io/latest/docs/tasks/traffic-management/ingress/secure-ingress/
#
################################################################################
#shopt -o -s errexit   #—Terminates  the shell script if a command returns an error code.
#shopt -o -s xtrace    #—Displays each command before it is executed.
#shopt -o -s nounset   #-No Variables without definition
set -euo pipefail
trap 'rc=$?; if [ $rc -ne 0 ]; then echo "ERROR: client_certificate.sh failed with exit code $rc" >&2; fi; exit $rc' EXIT

die() {
  echo "ERROR: $*" >&2
  exit 1
}

# Defaults
export client_secret="${1:-alfred@slainte.at}"
export host="${2:-*.${K8S_ENVIRONMENT}.slainte.at}"
export web_secret="${3:-k8s-selfsigned-ca-secret}"
export web_ns="${4:-cert-manager}"

# Validate required tools
command -v kubectl >/dev/null 2>&1 || command -v microk8s >/dev/null 2>&1 || die "kubectl or microk8s not found in PATH"
command -v openssl >/dev/null 2>&1 || die "openssl not found in PATH"

# Validate required environment variable
[ -n "${K8S_ENVIRONMENT:-}" ] || die "K8S_ENVIRONMENT environment variable not set"

echo "Setting up certificate directory..."
cert_dir="./${client_secret}"
rm -rf "$cert_dir"
mkdir -p "$cert_dir"

echo "Extracting CA certificate from $web_ns/$web_secret..."
kubectl -n "$web_ns" get secret "$web_secret" -o jsonpath='{.data.tls\.crt}' 2>/dev/null | \
  base64 -d > "$cert_dir/${web_secret}.crt" || \
  die "Failed to extract CA certificate from secret '$web_secret' in namespace '$web_ns'"

echo "Extracting CA private key from $web_ns/$web_secret..."
kubectl -n "$web_ns" get secret "$web_secret" -o jsonpath='{.data.tls\.key}' 2>/dev/null | \
  base64 -d > "$cert_dir/${web_secret}.key" || \
  die "Failed to extract CA private key from secret '$web_secret' in namespace '$web_ns'"

echo "Generating client certificate signing request (CSR)..."
openssl req -out "$cert_dir/${client_secret}.csr" \
  -newkey rsa:2048 -nodes \
  -keyout "$cert_dir/${client_secret}.key" \
  -subj "/C=AT/ST=Vienna/L=Vienna/O=${K8S_ENVIRONMENT}/OU=${host}/CN=${host}/emailAddress=${client_secret}/recipientName=${client_secret}" \
  || die "Failed to generate CSR"
echo ""
echo "Signing client certificate with CA..."
openssl x509 -req -in "$cert_dir/${client_secret}.csr" \
  -CA "$cert_dir/${web_secret}.crt" \
  -CAkey "$cert_dir/${web_secret}.key" \
  -set_serial 1 \
  -out "$cert_dir/${client_secret}.crt" \
  -days 365 \
  -sha256 \
  || die "Failed to sign client certificate"
echo "" 

echo "Creating PKCS#12 keystore for client certificate..."
openssl pkcs12 -export \
  -inkey "$cert_dir/${client_secret}.key" \
  -in "$cert_dir/${client_secret}.crt" \
  -certfile "$cert_dir/${web_secret}.crt" \
  -out "$cert_dir/${client_secret}.${host}.p12" \
  -passout "pass:${client_secret}" \
  || die "Failed to create PKCS#12 file"

echo "Cleaning up temporary files..."
rm -f "$cert_dir/${client_secret}.csr"
rm -f "$cert_dir/${web_secret}.key"

echo ""
echo "=== Certificate Generation Complete ==="
echo "Output directory: $cert_dir/"
echo "Files created:"
ls -lh "$cert_dir/"

echo ""
echo "To use these certificates:"
echo "  - Import $cert_dir/${client_secret}.p12 into your client (password: ${client_secret})"
echo "  - Or use PEM files: $cert_dir/${client_secret}.crt and $cert_dir/${client_secret}.key"
echo ""

exit 0