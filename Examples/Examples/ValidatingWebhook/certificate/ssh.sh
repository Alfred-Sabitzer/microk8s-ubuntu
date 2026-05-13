#!/bin/bash
############################################################################################
# Create Demo Zertificate
# https://github.com/alex-leonhardt/k8s-mutate-webhook/blob/master/ssl/ssl.sh
# https://www.civo.com/learn/kubernetes-admission-controllers-for-beginners
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition

export APP="${1}"
export APP="validatingwebhook-admission-svc"
export NAMESPACE="${2}"
export NAMESPACE="slainte"
export CSR_NAME="${APP}.${NAMESPACE}.svc"

# Check if admission registration is enabled
adm=$(kubectl api-versions | grep admissionregistration.k8s.io)
if [[ $adm == "" ]]; then
  echo "No Administration Registraten configured. ${adm}"
  echo "Please check your cluster-setup"
  exit 1
fi


openssl genrsa -out ${APP}.key 2048

cat >csr.conf<<EOF
[req]
default_bits = 2048
req_extensions = v3_req
distinguished_name = dn
prompt = no

[ dn ]
CN = system:node:kubernetes.default.svc
CN = system:node:validatingwebhook-admission-svc.slainte.svc
C = GB
ST = Canonical
L = Canonical
O = system:nodes
OU = system:nodes
CN = 127.0.0.1

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${APP}
DNS.2 = ${APP}.${NAMESPACE}
DNS.3 = ${APP}.${NAMESPACE}.svc
DNS.4 = ${APP}.${NAMESPACE}.svc.cluster
DNS.5 = ${APP}.${NAMESPACE}.svc.cluster.local
IP.1 = 127.0.0.1
EOF

authorityKeyIdentifier=keyid,issuer:always


openssl req -new -key ${APP}.key  -subj "/CN=system:node:kubernetes.default.svc/CN=system:node:validatingwebhook-admission-svc.slainte.svc/CN=127.0.0.1/" -out ${APP}.csr -config csr.conf
#openssl req -new -key certs/admission-tls.key -subj "/CN=validatingwebhook-admission-svc.slainte.svc"   -addext "subjectAltName = DNS:validatingwebhook-admission-svc.slainte.svc"  |
#openssl x509 -req -CA certs/ca.crt -CAkey certs/ca.key -CAcreateserial -out certs/admission-tls.crt
# "subjectAltName = DNS:abc.default.svc"
# Error from server (InternalError): error when creating "x.yaml": Internal error occurred: failed calling webhook "k8s.slainte.at":
# failed to call webhook: Post "https://validatingwebhook-admission-svc.slainte.svc:443/validate/pods?timeout=10s": tls: failed to verify certificate: x509: certificate signed by unknown authority
# Error from server (InternalError): error when creating "x.yaml": Internal error occurred: failed calling webhook "validatingwebhook-admission-svc.slainte.svc": failed to call webhook: Post "https://validatingwebhook-admission-svc.slainte.svc:443/validate/pods?timeout=10s": tls: failed to verify certificate: x509: certificate signed by unknown authority

echo "... deleting existing csr, if any"
kubectl delete csr ${CSR_NAME} || :

echo "... creating kubernetes CSR object"
cat >csr.yaml<<EOF
# https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${CSR_NAME}
  namespace: ${NAMESPACE}
spec:
  groups:
  - system:authenticated
  request: $(cat ${APP}.csr | base64 | tr -d '\n')
  signerName: kubernetes.io/kubelet-serving
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF

kubectl create -f csr.yaml

SECONDS=0
while true; do
  echo "... waiting for csr to be present in kubernetes"
  echo "kubectl get csr ${CSR_NAME}"
  kubectl get csr ${CSR_NAME} > /dev/null 2>&1
  if [ "$?" -eq 0 ]; then
      break
  fi
  if [[ $SECONDS -ge 60 ]]; then
    echo "[!] timed out waiting for csr"
    exit 1
  fi
  sleep 2
done

kubectl certificate approve ${CSR_NAME}

SECONDS=0
while true; do
  echo "... waiting for serverCert to be present in kubernetes"
  echo "kubectl get csr ${CSR_NAME} -o jsonpath='{.status.certificate}'"
  serverCert=$(kubectl get csr ${CSR_NAME} -o jsonpath='{.status.certificate}')
  if [[ $serverCert != "" ]]; then
    break
  fi
  if [[ $SECONDS -ge 60 ]]; then
    echo "[!] timed out waiting for serverCert"
    exit 1
  fi
  sleep 2
done

echo ${serverCert} | openssl base64 -d -A -out ${APP}.pem
openssl x509 -in ${APP}.pem -text

echo "Creating k8s Secret"
kubectl delete secret ${APP} --namespace ${NAMESPACE} || :
kubectl create secret tls ${APP} --namespace ${NAMESPACE} \
    --cert "${APP}.pem" \
    --key "${APP}.key"

