#!/usr/bin/env bash
############################################################################################
# Verify Certificates
#
############################################################################################
#shopt -o -s errexit #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace  #—Displays each command before it is executed.
#shopt -o -s nounset #-No Variables without definition

set -euo pipefail

CERT="$1"

# openssl verify \
#     -CAfile ~/pki/k8s-intermediate-ca-secret/chain.pem  \
#     "$CERT"

openssl verify \
    -CAfile ~/pki/root/chain.pem \
    -untrusted "$CERT" \
    "$CERT"