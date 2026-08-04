#!/bin/bash
############################################################################################
#
# Extract the specific client certificate from the cert-manager secret and save it to a file.
#
############################################################################################
#shopt -o -s errexit #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace  #—Displays each command before it is executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail

export PASSWORD="${1:-changeit}"

secret_name="alfred-slainte-at-tls"
namespace="istio-system"

rm -rf ~/pki/$secret_name || true
mkdir -p ~/pki/$secret_name
kubectl get secret \
    -n $namespace $secret_name \
    -o jsonpath="{.data.ca\.crt}" | base64 -d |  tee ~/pki/$secret_name/ca.crt
kubectl get secret \
    -n $namespace $secret_name \
     -o jsonpath="{.data.tls\.crt}" | base64 -d |  tee ~/pki/$secret_name/tls.crt
kubectl get secret \
    -n $namespace $secret_name \
    -o jsonpath="{.data.tls\.key}" | base64 -d |  tee ~/pki/$secret_name/tls.key
kubectl get secret \
    -n cert-manager k8s-root-ca-secret \
    -o jsonpath="{.data.ca\.crt}" | base64 -d |  tee ~/pki/$secret_name/root.crt

# create a chain file that contains the intermediate and root CA certificates
cat ~/pki/$secret_name/ca.crt ~/pki/$secret_name/root.crt > ~/pki/$secret_name/ca-bundle.crt

# export the certificate and private key to a PKCS#12 file
openssl pkcs12 \
    -export \
    -inkey ~/pki/$secret_name/tls.key \
    -in ~/pki/$secret_name/tls.crt \
    -certfile ~/pki/$secret_name/root.crt \
    -out ~/pki/$secret_name/tls.p12 \
    -passout pass:${PASSWORD}

#
echo "$secret_name certificate extracted to ~/pki/$secret_name/"
##