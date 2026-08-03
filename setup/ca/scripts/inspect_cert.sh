#!/usr/bin/env bash

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