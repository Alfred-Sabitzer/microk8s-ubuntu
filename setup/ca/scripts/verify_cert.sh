#!/bin/bash
############################################################################################
#
# Script to verify a client certificate
#
############################################################################################
#shopt -o -s errexit #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace  #—Displays each command before it is executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 <certificate.pem> [ca-file.pem]
Verify a PEM certificate using either a provided CA file or the system trust store.
EOF
  exit 1
}

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
  usage
fi

CERT="$1"
CAFILE="${2:-}"

if [ ! -f "$CERT" ]; then
  echo "Error: certificate file not found: $CERT"
  exit 1
fi

if [ -n "$CAFILE" ]; then
  if [ ! -f "$CAFILE" ]; then
    echo "Error: CA file not found: $CAFILE"
    exit 1
  fi
  openssl verify -CAfile "$CAFILE" "$CERT"
else
  if [ -f /etc/ssl/certs/ca-certificates.crt ]; then
    openssl verify -CAfile /etc/ssl/certs/ca-certificates.crt "$CERT"
  elif [ -f /etc/pki/tls/certs/ca-bundle.crt ]; then
    openssl verify -CAfile /etc/pki/tls/certs/ca-bundle.crt "$CERT"
  else
    echo "Error: no system CA bundle found. Provide a CA file explicitly."
    exit 1
  fi
fi
