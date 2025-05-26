# Admission Controller

Please consider https://bshayr29.medium.com/build-your-own-admission-controllers-in-kubernetes-using-go-bef8ba38d595
and https://github.com/douglasmakey/admissioncontroller/tree/master
https://dev.to/douglasmakey/implementing-a-simple-k8s-admission-controller-in-go-2dcg
https://fespinoza.net/2021-04-11/Kubernetes-Admission-Controller

Es gibt auch dynamische Admission-Controlers, die mit Webhooks arbeitern https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/

Standard-Admission-Controllers in Kubernetes sind  https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/

# Example

````bash
#!/bin/bash

echo "Creating certificates"
mkdir certs
openssl req -nodes -new -x509 -keyout certs/ca.key -out certs/ca.crt -subj "/CN=Admission Controller Demo"
openssl genrsa -out certs/admission-tls.key 2048
openssl req -new -key certs/admission-tls.key -subj "/CN=admission-server.default.svc" | openssl x509 -req -CA certs/ca.crt -CAkey certs/ca.key -CAcreateserial -out certs/admission-tls.crt

echo "Creating k8s Secret"
kubectl create secret tls admission-tls \
    --cert "certs/admission-tls.crt" \
    --key "certs/admission-tls.key"

echo "Creating k8s admission deployment"
kubectl create -f deployment.yaml

echo "Creating k8s webhooks for demo"
CA_BUNDLE=$(cat certs/ca.crt | base64 | tr -d '\n')
sed -e 's@${CA_BUNDLE}@'"$CA_BUNDLE"'@g' <"webhooks.yaml" | kubectl create -f -
````


ca-bundle https://github.com/douglasmakey/admissioncontroller/blob/master/demo/deploy.sh

# Secret

````bash
#!/bin/bash
############################################################################################
#
# Erzeugen der Kubernetes Secrets aus bereits vorhandenen Zertifikaten
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition

cat <<EOF > k8s-slainte-at-tls.yaml
#
# k8s-slainte-at-tls
#
---
#
apiVersion: v1
kind: Secret
metadata:
name: k8s-slainte-at-tls
namespace: slainte
type: kubernetes.io/tls
data:
EOF
echo "  tls.crt: $(cat /home/alfred/k8s/SecureRegistry/pem/server.crt | base64 -w 0)"  >> k8s-slainte-at-tls.yaml
echo "  tls.key: $(cat /home/alfred/k8s/SecureRegistry/pem/server.key | base64 -w 0)" >> k8s-slainte-at-tls.yaml
#
````

# Cert

````bash
#!/bin/bash
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
#shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition

NODAYS=3650
FULLHOST="slainte"
KEYLEN=4096
CERTDIR="./"
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
	    -trustout \
            $opts \
            -out $certfile
}

mkdir -p ${CERTDIR}
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

generate_cert server "${FULLHOST} - Server-only" "-extfile ${CERTDIR}/openssl.cnf -extensions server_cert"
generate_cert client "${FULLHOST} - Client-only" "-extfile ${CERTDIR}/openssl.cnf -extensions client_cert"
generate_cert redis "${FULLHOST} - Generic-cert" " "

[ -f ${CERTDIR}/redis.dh ] || openssl dhparam -out ${CERTDIR}/redis.dh 1024

echo "Alle Zertifikate generiert"
ls -lsia ${CERTDIR}

````

