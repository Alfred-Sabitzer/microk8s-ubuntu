#!/bin/bash
############################################################################################
#
# Script to create a client certificates
#
############################################################################################
#shopt -o -s errexit #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace  #—Displays each command before it is executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail

export EMAIL="${1:-alfred@slainte.at}"
export CN="${2:-changeit}"
export PASSWORD="${3:-changeit}"
export DAYS="${4:-365}"
export NAMESPACE="${5:-client-certificates}"

export secret_name=foo=$(echo "${EMAIL}" | sed  \
    -e 's/\@/\-/g' \
    -e 's/\./\-/g')


rm -rf ~/pki/$secret_name || true
mkdir -p ~/pki/$secret_name

cat << EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ${secret_name}
  namespace: ${NAMESPACE}
spec:
  secretName: ${secret_name}
  # Die E-Mail-Adresse für das S/MIME-Zertifikat
  emailAddresses:
    - ${EMAIL}
  # Gemeinsamer Name (wird oft als Anzeigename im Mail-Client genutzt)
  commonName: ${CN}
  duration: $(( ${DAYS} * 24 ))h # Dauer in Stunden
  renewBefore: 360h # 15 Tage vor Ablauf erneuern
  privateKey:
    algorithm: RSA
    encoding: PKCS1
    size: 2048
  # Essentiell für S/MIME (Client-Auth & Mail-Schutz)
  usages:
    - digital signature
    - key encipherment
    - client auth
    - email protection
  issuerRef:
    group: cert-manager.io
    kind: ClusterIssuer
    name: k8s-intermediate-issuer # <--- Nutzt dieselbe CA wie das Gateway    
Verwende Code mit Vorsicht.
EOF


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