#!/usr/bin/env bash
set -euo pipefail

mkdir -p pki/root

openssl genpkey \
    -algorithm RSA \
    -pkeyopt rsa_keygen_bits:4096 \
    -out pki/root/root.key.pem

chmod 600 pki/root/root.key.pem

openssl req \
    -config openssl/openssl-root.cnf \
    -key pki/root/root.key.pem \
    -new \
    -x509 \
    -days 7300 \
    -sha384 \
    -extensions v3_ca \
    -out pki/root/root.crt.pem

echo "Root CA created."