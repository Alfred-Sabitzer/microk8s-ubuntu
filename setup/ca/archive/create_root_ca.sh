#!/usr/bin/env bash
############################################################################################
# Generate root CA
#
############################################################################################
#shopt -o -s errexit #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace  #—Displays each command before it is executed.
#shopt -o -s nounset #-No Variables without definition

set -euo pipefail

CERT_CN="${1:-Example Root CA}"
CERT_O="${2:-Example}"
CERT_C="${3:-US}"

rm -rf ~/pki/root || true
mkdir -p ~/pki/root

openssl genpkey \
    -algorithm RSA \
    -pkeyopt rsa_keygen_bits:4096 \
    -out ~/pki/root/root.key.pem

chmod 600 ~/pki/root/root.key.pem

cat >> /tmp/root.cnf <<EOF
[ req ]

distinguished_name=req_distinguished_name
x509_extensions=v3_ca
prompt=no

[ req_distinguished_name ]

CN=${CERT_CN}
O=${CERT_O}
C=${CERT_C}

[v3_ca]

subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always,issuer
basicConstraints=critical,CA:true
keyUsage=critical,keyCertSign,cRLSign

EOF

openssl req \
    -config /tmp/root.cnf \
    -key ~/pki/root/root.key.pem \
    -new \
    -x509 \
    -days 7300 \
    -sha384 \
    -extensions v3_ca \
    -out ~/pki/root/root.crt.pem

echo "Root CA created."