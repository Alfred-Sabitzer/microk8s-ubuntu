#!/bin/sh
############################################################################################
# Inspiration: https://github.com/redis/redis/blob/unstable/utils/gen-test-certs.sh
# Generiere Zertifikate
#
#   ${CERTDIR}/ca.{crt,key}          Self signed CA certificate.
#   ${CERTDIR}/redis.{crt,key}       A certificate with no key usage/policy restrictions.
#   ${CERTDIR}/client.{crt,key}      A certificate restricted for SSL client usage.
#   ${CERTDIR}/server.{crt,key}      A certificate restricted for SSL server usage.
#   ${CERTDIR}/redis.dh              DH Params file.
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
#shopt -o -s nounset #-No Variables without definition

NODAYS=3650
FULLHOST="${1:-slainte.at}"
KEYLEN=4096
CERTDIR="./${FULLHOST}"
#CERTDIR="tls/certs"  # Das ist für lokale Tests

generate_cert() {
    local name=$1
    local cn="$2"
    local opts="$3"

    local keyfile=${CERTDIR}/${name}.key
    local certfile=${CERTDIR}/${name}.crt

    [ -f $keyfile ] || openssl genrsa -out $keyfile ${KEYLEN}
    openssl req \
        -new -sha256 \
        -subj "/C=CA/ST=QC/O=Slainte/CN=$cn" \
        -key $keyfile | \
        openssl x509 \
            -req -sha256 \
            -CA ${CERTDIR}/ca.crt \
            -CAkey ${CERTDIR}/ca.key \
            -CAserial ${CERTDIR}/ca.txt \
            -CAcreateserial \
            -days ${NODAYS} \
            $opts \
            -out $certfile
}

###

# Typical cryptographic algorithms include:
# Algorithm
# Usage
# RSA 2048      # Default in many deployments
# RSA 4096      # High-security environments
# ECDSA P-256   # Modern clusters requiring smaller certificates
# ECDSA P-384   # Enhanced security
# Ed25519       # Limited support in Kubernetes ecosystems
# Hash algorithms:
#     • SHA-256
#     • SHA-384
#     • SHA-512
# Older algorithms such as MD5 and SHA-1 are deprecated and must not be used.


#!/usr/bin/env bash
set -euo pipefail

# 1. SETUP LOGGING & CONFIG
echo "=== Generating Secure mTLS Certificate Infrastructure ==="

# Define organization details
ORG_DN="/C=US/ST=California/L=San Francisco/O=MyCompany/OU=Security"

# Create a secure OpenSSL config for SAN (Subject Alternative Names)
cat <<EOF > server_ext.cnf
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = server.local
IP.1 = 127.0.0.1
EOF

cat <<EOF > client_ext.cnf
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature
extendedKeyUsage = clientAuth
EOF

# 2. GENERATE ROOT CA (The Trust Anchor)
echo "-> Creating Private Root CA..."
# Generate private key
openssl ecparam -name prime256v1 -genkey -noout -out rootCA.key
# Generate self-signed Root Certificate (Valid for 10 years / 3650 days)
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 \
  -subj "$ORG_DN/CN=MyPrivateRootCA" -out rootCA.crt

# 3. GENERATE SERVER CERTIFICATE
echo "-> Creating Server Certificate..."
# Generate server private key
openssl ecparam -name prime256v1 -genkey -noout -out server.key
# Generate Certificate Signing Request (CSR)
openssl req -new -key server.key -subj "$ORG_DN/CN=server.local" -out server.csr
# Sign the server certificate using the Root CA (Valid for 1 year / 365 days)
openssl x509 -req -in server.csr -CA rootCA.crt -CAkey rootCA.key \
  -CAcreateserial -out server.crt -days 365 -sha256 -extfile server_ext.cnf

# 4. GENERATE CLIENT CERTIFICATE
echo "-> Creating Client Certificate..."
# Generate client private key
openssl ecparam -name prime256v1 -genkey -noout -out client.key
# Generate client CSR
openssl req -new -key client.key -subj "$ORG_DN/CN=client.local" -out client.csr
# Sign the client certificate using the Root CA (Valid for 1 year / 365 days)
openssl x509 -req -in client.csr -CA rootCA.crt -CAkey rootCA.key \
  -CAcreateserial -out client.crt -days 365 -sha256 -extfile client_ext.cnf

# 5. CLEANUP TEMPORARY CONFIGS
rm -f server.csr client.csr server_ext.cnf client_ext.cnf rootCA.srl
echo "=== Success! Certificates Generated ==="
ls -l *.key *.crt





How to generate a proper client certificate

You should create a CSR:

openssl req \
    -new \
    -newkey rsa:2048 \
    -nodes \
    -keyout client.key \
    -out client.csr

Create an extension file:

basicConstraints = CA:FALSE
keyUsage = digitalSignature,keyEncipherment
extendedKeyUsage = clientAuth
subjectAltName = email:alfred@slainte.at

Then sign it:

openssl x509 \
    -req \
    -in client.csr \
    -CA ca.crt \
    -CAkey ca.key \
    -CAcreateserial \
    -days 365 \
    -extfile client.ext \
    -out client.crt

The resulting certificate should show:

Version: 3 (0x2)

X509v3 Key Usage:
    Digital Signature, Key Encipherment

X509v3 Extended Key Usage:
    TLS Web Client Authentication



###

mkdir -p ${CERTDIR}
rm -rf ${CERTDIR}/*

[ -f ${CERTDIR}/ca.key ] || openssl genrsa -out ${CERTDIR}/ca.key ${KEYLEN}
openssl req \
    -x509 -new -nodes -sha256 \
    -key ${CERTDIR}/ca.key \
    -days ${NODAYS} \
    -subj '/C=CA/ST=QC/O=Slainte/CN=Certificate Authority' \
    -out ${CERTDIR}/ca.crt

cat > ${CERTDIR}/openssl.cnf <<_END_
[ server_cert ]
keyUsage = digitalSignature, keyEncipherment
nsCertType = server
[ client_cert ]
keyUsage = digitalSignature, keyEncipherment
nsCertType = client
_END_

generate_cert ${FULLHOST}_server "${FULLHOST} - Server-only" "-extfile ${CERTDIR}/openssl.cnf -extensions server_cert"
generate_cert ${FULLHOST}_client "${FULLHOST} - Client-only" "-extfile ${CERTDIR}/openssl.cnf -extensions client_cert"
generate_cert ${FULLHOST}_generic "${FULLHOST} - Generic-cert" " "

[ -f ${CERTDIR}/redis.dh ] || openssl dhparam -out ${CERTDIR}/${FULLHOST}.dh 1024

cat  ${CERTDIR}/*.crt > ${CERTDIR}/${FULLHOST}_chain.pem
cat  ${CERTDIR}/*.key > ${CERTDIR}/${FULLHOST}_key.pem
chmod 400 ${CERTDIR}/*.key
chmod 444 ${CERTDIR}/*.crt
chmod 444 ${CERTDIR}/${FULLHOST}_chain.pem
chmod 400 ${CERTDIR}/${FULLHOST}_key.pem

echo "Alle Zertifikate generiert"
ls -lsia ${CERTDIR}
