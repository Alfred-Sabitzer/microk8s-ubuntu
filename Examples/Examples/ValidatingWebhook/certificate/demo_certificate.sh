#!/bin/bash
############################################################################################
# Create Demo Zertificate
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition

echo "Creating certificates"
mkdir certs
openssl req -nodes -new -x509 -keyout certs/ca.key -out certs/ca.crt -subj "/CN=Admission Controller Demo"
openssl genrsa -out certs/admission-tls.key 2048
openssl req -new -key certs/admission-tls.key -subj "/CN=validatingwebhook-admission-svc.slainte.svc"   -addext "subjectAltName = DNS:validatingwebhook-admission-svc.slainte.svc"  | openssl x509 -req -CA certs/ca.crt -CAkey certs/ca.key -CAcreateserial -out certs/admission-tls.crt

echo "Creating k8s Secret"
kubectl delete secret admission-tls --namespace slainte
kubectl create secret tls admission-tls --namespace slainte \
    --cert "certs/admission-tls.crt" \
    --key "certs/admission-tls.key"

####

mkdir certs
openssl genrsa -out certs/ca.key 2048
openssl req -new -x509 -days 365 -key certs/ca.key -subj "/C=AT/ST=GD/L=SZ/O=Slainte, Inc./CN=Slainte Root CA" -out certs/ca.crt

openssl req -newkey rsa:2048 -nodes -keyout certs/admission-tls.key -subj "/C=AT/ST=GD/L=SZ/O=Slainte, Inc./CN=*.slainte.svc" -out certs/admission-tls.csr
openssl x509 -req -extfile <(printf "subjectAltName=DNS:validatingwebhook-admission-svc.slainte.svc") -days 365 -in certs/admission-tls.csr -CA certs/ca.crt -CAkey certs/ca.key -CAcreateserial -out certs/admission-tls.crt

echo "Creating k8s Secret"
kubectl delete secret admission-tls --namespace slainte
kubectl create secret tls admission-tls --namespace slainte \
    --cert "certs/admission-tls.crt" \
    --key "certs/admission-tls.key"


# https://medium.com/ovni/writing-a-very-basic-kubernetes-mutating-admission-webhook-398dbbcb63ec

# https://github.com/alex-leonhardt/k8s-mutate-webhook/blob/master/ssl/ssl.sh