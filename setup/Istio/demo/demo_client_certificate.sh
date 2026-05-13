#!/bin/bash
################################################################################
#
# create a client certificate for mutual TLS
#
# See https://istio.io/latest/docs/tasks/traffic-management/ingress/secure-ingress/
################################################################################
#shopt -o -s errexit   #—Terminates  the shell script if a command returns an error code.
#shopt -o -s xtrace    #—Displays each command before it is executed.
#shopt -o -s nounset   #-No Variables without definition
set -euo pipefail
export client_secret=${1:-"alfred@slainte.at"}
export host=${2:-${K8S_ENVIRONMENT}.http-echo-mutual.slainte.at}
export web_secret=${3:-"k8s-selfsigned-ca-secret"}
export web_ns=${4:-"cert-manager"}
export INGRESS_NAME=istio-ingressgateway
export INGRESS_NS=istio-system
#
echo "Get Ingress Gateway details for accessing the application"
export INGRESS_HOST=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export INGRESS_PORT=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')${client_secret}
export SECURE_INGRESS_PORT=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
export TCP_INGRESS_PORT=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.spec.ports[?(@.name=="tcp")].port}')
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
# Directory for client certs
rm -rf ./${client_secret}
mkdir -p ./${client_secret}
# we also need the correct CA cert
kubectl -n ${web_ns} get secret ${web_secret} -o jsonpath='{.data.tls\.crt}' | base64 -d > ./${client_secret}/${web_secret}.crt
kubectl -n ${web_ns} get secret ${web_secret} -o jsonpath='{.data.tls\.key}' | base64 -d > ./${client_secret}/${web_secret}.key
# let's create a client cert signed by the same CA
openssl req -out ./${client_secret}/${client_secret}.csr -newkey rsa:2048 -nodes -keyout ./${client_secret}/${client_secret}.key -subj "/C=AT/ST=Vienna/L=Vienna/O=${K8S_ENVIRONMENT}/OU=${host}/CN=${client_secret}/emailAddress=${client_secret}"
openssl x509 -req -sha256 -days 365 -CA ./${client_secret}/${web_secret}.crt -CAkey ./${client_secret}/${web_secret}.key -set_serial 1 -in ./${client_secret}/${client_secret}.csr -out ./${client_secret}/${client_secret}.crt

# Show created client cert details
openssl req -in ./${client_secret}/${client_secret}.csr -noout -text
#
# Create a PKCS#12 file for the client certificate
#
openssl pkcs12 -export \
  -inkey ./${client_secret}/${client_secret}.key \
  -in ./${client_secret}/${client_secret}.crt \
  -certfile ./${client_secret}/${web_secret}.crt \
  -out ./${client_secret}/${client_secret}.p12 -passout pass:${client_secret}
#
# clean up
#
# 528224 4 -rw-rw-r--  1 ansible ansible  916 Dez 29 11:28 alfred@slainte.at.crt
# 528233 4 -rw-rw-r--  1 ansible ansible 1090 Dez 29 11:28 alfred@slainte.at.csr
# 528251 4 -rw-------  1 ansible ansible 1704 Dez 29 11:28 alfred@slainte.at.key
# 528255 4 -rw-------  1 ansible ansible 2803 Dez 29 11:28 alfred@slainte.at.p12
# 528256 4 -rw-rw-r--  1 ansible ansible  570 Dez 29 11:28 k8s-selfsigned-ca-secret.crt
# 528257 4 -rw-rw-r--  1 ansible ansible  227 Dez 29 11:28 k8s-selfsigned-ca-secret.key
rm -f ./${client_secret}/${client_secret}.csr
rm -f ./${client_secret}/${web_secret}.key 

exit 0