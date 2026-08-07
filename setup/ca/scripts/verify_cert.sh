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
CHAIN="$2"

openssl verify \
    -CAfile "$CHAIN" \
    -untrusted "$CERT" \
    "$CERT"