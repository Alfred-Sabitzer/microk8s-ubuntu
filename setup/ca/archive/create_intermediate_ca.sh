#!/usr/bin/env bash
############################################################################################
# Generate Intermediate CA
#
############################################################################################
#shopt -o -s errexit #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace  #—Displays each command before it is executed.
#shopt -o -s nounset #-No Variables without definition

set -euo pipefail

CERT_CN="${1:-Example Root CA}"
CERT_O="${2:-Example}"
CERT_C="${3:-US}"

rm -rf ~/pki/intermediate || true
mkdir -p ~/pki/intermediate

cat >> /tmp/intermediate.cnf <<EOF
[ req ]

distinguished_name=req_distinguished_name
prompt=no

[ req_distinguished_name ]

CN=${CERT_CN}
O=${CERT_O}
C=${CERT_C}

[v3_intermediate_ca]

subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
basicConstraints=critical,CA:true,pathlen:0
keyUsage=critical,keyCertSign,cRLSign

EOF

openssl genpkey \
    -algorithm RSA \
    -pkeyopt rsa_keygen_bits:4096 \
    -out ~/pki/intermediate/intermediate.key.pem

openssl req \
    -new \
    -key ~/pki/intermediate/intermediate.key.pem \
    -config /tmp/intermediate.cnf \
    -out ~/pki/intermediate/intermediate.csr.pem

openssl x509 \
    -req \
    -days 3650 \
    -sha384 \
    -in ~/pki/intermediate/intermediate.csr.pem \
    -CA ~/pki/root/root.crt.pem \
    -CAkey ~/pki/root/root.key.pem \
    -CAcreateserial \
    -extensions v3_intermediate_ca \
    -extfile /tmp/intermediate.cnf \
    -out ~/pki/intermediate/intermediate.crt.pem

cat \
    ~/pki/intermediate/intermediate.crt.pem \
    ~/pki/root/root.crt.pem \
    > ~/pki/intermediate/chain.pem

echo "Intermediate created."