#!/bin/bash
################################################################################
#
# Local test for httpbin sample
#
# See https://istio.io/latest/docs/tasks/traffic-management/ingress/secure-ingress/
################################################################################
#shopt -o -s errexit   #—Terminates  the shell script if a command returns an error code.
#shopt -o -s xtrace    #—Displays each command before it is executed.
#shopt -o -s nounset   #-No Variables without definition
set -euo pipefail
export client_secret=${1:-"alfred@slainte.at"}
export host=${2:-${K8S_ENVIRONMENT}.http-echo-mutual.slainte.at}
export web_secret=${3:-"k8s-root-secret"}
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
openssl req -out ./${client_secret}/${client_secret}.csr -newkey rsa:2048 -nodes -keyout ./${client_secret}/${client_secret}.key -subj "/C=AT/ST=Vienna/L=Vienna/O=Client Company/OU=Platform Engineering/CN=${client_secret}/emailAddress=${client_secret}"
# Create a config file for the extensions
cat > ./${client_secret}/${client_secret}.cnf <<- EOM
[ v3_client ]
basicConstraints = critical, CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
subjectAltName = @alt_names

[ alt_names ]
email.1 = ${client_secret}
DNS.1 = ${host}
EOM

# Sign the client certificate with the CA
openssl x509 -req \
  -in ./${client_secret}/${client_secret}.csr \
  -CA ./${client_secret}/${web_secret}.crt \
  -CAkey ./${client_secret}/${web_secret}.key \
  -set_serial 1 \
  -out ./${client_secret}/${client_secret}.crt \
  -days 365 \
  -sha256 \
  -extfile ./${client_secret}/${client_secret}.cnf \
  -extensions v3_client

# Show created client cert details
openssl req -in ./${client_secret}/${client_secret}.csr -noout -text
#
openssl pkcs12 -export \
  -inkey ./${client_secret}/${client_secret}.key \
  -in ./${client_secret}/${client_secret}.crt \
  -certfile ./${client_secret}/${web_secret}.crt \
  -out ./${client_secret}/${client_secret}.p12 -passout pass:${client_secret}
#
echo ""
echo "accessing ${host} via INGRESS_HOST=$INGRESS_HOST on SECURE_INGRESS_PORT=$SECURE_INGRESS_PORT with mutual TLS"
echo ""
echo ""
echo ""
echo curl -v -k -H${host} --resolve "${host}:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
  --cert ./${client_secret}/${client_secret}.crt \
  --key ./${client_secret}/${client_secret}.key \
  --cacert ./${client_secret}/${web_secret}.crt \
  "https://${host}:$SECURE_INGRESS_PORT/"
echo ""
echo ""
echo ""
curl -v -k -H${host} --resolve "${host}:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
  --cert ./${client_secret}/${client_secret}.crt \
  --key ./${client_secret}/${client_secret}.key \
  --cacert ./${client_secret}/${web_secret}.crt \
  "https://${host}:$SECURE_INGRESS_PORT/"


exit 0

ansible@k8stest:~/gitlab/microk8s-ubuntu/setup/Istio/demo$ k get secrets -n istio-system 
NAME                          TYPE                DATA   AGE
alfred-at-slainte-at          kubernetes.io/tls   3      50s
http-echo-mutual-slainte-at   kubernetes.io/tls   3      50s
http-echo-simple-slainte-at   kubernetes.io/tls   3      6m14s
istio-ca-secret               istio.io/ca-root    5      12h
ansible@k8stest:~/gitlab/microk8s-ubuntu/setup/Istio/demo$ 


kubectl -n istio-system get secret http-echo-mutual-slainte-at -o jsonpath='{.data.tls\.crt}' | base64 -d > client.crt
kubectl -n istio-system get secret http-echo-mutual-slainte-at -o jsonpath='{.data.tls\.key}' | base64 -d > client.key
kubectl -n istio-system get secret http-echo-mutual-slainte-at -o jsonpath='{.data.ca\.crt}'  | base64 -d > ca.crt

alfred-at-slainte-at

kubectl -n istio-system get secret alfred-at-slainte-at -o jsonpath='{.data.tls\.crt}' | base64 -d > client.crt
kubectl -n istio-system get secret alfred-at-slainte-at -o jsonpath='{.data.tls\.key}' | base64 -d > client.key
kubectl -n istio-system get secret alfred-at-slainte-at -o jsonpath='{.data.ca\.crt}'  | base64 -d > ca.crt


curl -v -k -Htest.http-echo-mutual.slainte.at --resolve test.http-echo-mutual.slainte.at:443:10.242.64.202 \
  --cert client.crt \
  --key client.key \
  --cacert ca.crt \
  https://test.http-echo-mutual.slainte.at:443/


