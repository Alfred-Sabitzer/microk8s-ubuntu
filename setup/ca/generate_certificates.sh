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
