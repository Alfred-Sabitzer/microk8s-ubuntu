#!/usr/bin/env bash
############################################################################################
# Generate Certificates
#
############################################################################################
#shopt -o -s errexit #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace  #—Displays each command before it is executed.
#shopt -o -s nounset #-No Variables without definition

set -euo pipefail

NAME="$1"
TYPE="${2:-server}"
PASSWORD="${3:-changeit}"
EMAIL="${4:-email@${NAME}}"

rm -rf ~/pki/issued/$NAME || true
mkdir -p ~/pki/issued/$NAME

secret_name="k8s-intermediate-ca-secret"
KEY=~/pki/issued/$NAME/$NAME.key.pem
CSR=~/pki/issued/$NAME/$NAME.csr.pem
CRT=~/pki/issued/$NAME/$NAME.crt.pem
P12=~/pki/issued/$NAME/$NAME.p12

openssl genpkey \
    -algorithm RSA \
    -pkeyopt rsa_keygen_bits:4096 \
    -out "$KEY"

cat > /tmp/${NAME}.cnf <<EOF
basicConstraints=CA:FALSE
keyUsage=digitalSignature,keyEncipherment

EOF

if [[ "$TYPE" == "server" ]]; then

cat >> /tmp/${NAME}.cnf <<EOF
subjectAltName=DNS:${NAME}
basicConstraints = critical, CA:FALSE
keyUsage         = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName   = @alt_names

EOF

elif [[ "$TYPE" == "client" ]]; then

cat >> /tmp/${NAME}.cnf <<EOF
basicConstraints = critical, CA:FALSE
keyUsage         = critical, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
subjectAltName = email:${EMAIL}

EOF


else

cat >> /tmp/${NAME}.cnf <<EOF
basicConstraints = critical, CA:FALSE
keyUsage         = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = DNS:${NAME}

EOF

fi

openssl req \
    -new \
    -key "$KEY" \
    -subj "/CN=$NAME" \
    -out "$CSR"

openssl x509 \
    -req \
    -days 825 \
    -sha384 \
    -in "$CSR" \
    -CA ~/pki/$secret_name/tls.crt \
    -CAkey ~/pki/$secret_name/tls.key \
    -CAcreateserial \
    -extfile /tmp/${NAME}.cnf \
    -out "$CRT"

cat \
    "$CRT" \
    ~/pki/$secret_name/tls.crt \
    ~/pki/$secret_name/ca.crt \
    > ~/pki/issued/$NAME/fullchain.pem

openssl pkcs12 \
    -export \
    -inkey "$KEY" \
    -in "$CRT" \
    -certfile ~/pki/$secret_name/ca.crt \
    -out "$P12" \
    -passout pass:${PASSWORD}

echo "Created certificate for $NAME"