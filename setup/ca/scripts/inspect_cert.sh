#!/usr/bin/env bash
############################################################################################
# Check Certificates
#
############################################################################################
#shopt -o -s errexit #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace  #—Displays each command before it is executed.
#shopt -o -s nounset #-No Variables without definition

set -euo pipefail

FILE="$1"

echo
echo "================================="
echo "Certificate"
echo "================================="

openssl x509 \
    -in "$FILE" \
    -text \
    -noout

echo
echo "================================="
echo "Fingerprint SHA256"
echo "================================="

openssl x509 \
    -in "$FILE" \
    -fingerprint \
    -sha256 \
    -noout

echo
echo "================================="
echo "Subject"
echo "================================="

openssl x509 \
    -in "$FILE" \
    -subject \
    -issuer \
    -dates \
    -serial \
    -noout