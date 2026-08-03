#!/usr/bin/env bash
set -euo pipefail

mkdir -p pki/intermediate

openssl genpkey \
    -algorithm RSA \
    -pkeyopt rsa_keygen_bits:4096 \
    -out pki/intermediate/intermediate.key.pem

openssl req \
    -new \
    -key pki/intermediate/intermediate.key.pem \
    -config openssl/openssl-intermediate.cnf \
    -out pki/intermediate/intermediate.csr.pem

openssl x509 \
    -req \
    -days 3650 \
    -sha384 \
    -in pki/intermediate/intermediate.csr.pem \
    -CA pki/root/root.crt.pem \
    -CAkey pki/root/root.key.pem \
    -CAcreateserial \
    -extensions v3_intermediate_ca \
    -extfile openssl/openssl-intermediate.cnf \
    -out pki/intermediate/intermediate.crt.pem

cat \
    pki/intermediate/intermediate.crt.pem \
    pki/root/root.crt.pem \
    > pki/intermediate/chain.pem

echo "Intermediate created."