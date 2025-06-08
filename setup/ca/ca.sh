#!/bin/bash
############################################################################################
#
# Createe CA for internal use in MicroK8s
#
# https://medium.com/geekculture/a-simple-ca-setup-with-kubernetes-cert-manager-bc8ccbd9c2
# https://cert-manager.io/docs/concepts/issuer/
# https://cert-manager.io/docs/configuration/issuers/
# https://cert-manager.io/docs/configuration/selfsigned/
#
# https://medium.com/@manojkumar_41904/to-generate-a-self-signed-certificate-for-use-with-a-kubernetes-k8s-application-you-can-follow-e1398fb563fc
# https://www.thesslstore.com/blog/setting-up-your-own-certificate-authority/
# https://arminreiter.com/2022/01/create-your-own-certificate-authority-ca-using-openssl/
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail

# Get the directory of the current script
indir=$(dirname "$0")

echo "Checking if microk8s is installed..."
if ! command -v microk8s &> /dev/null; then
  echo "Error: microk8s is not installed."
  exit 1
fi

if [ ! -f "${indir}/ca.yaml" ]; then
  echo "Error: ca.yaml not found in ${indir}."
  exit 1
fi

echo "Applying CA configuration..."
until microk8s kubectl apply -f "${indir}/ca.yaml"; do
  echo "Retrying ca.yaml apply in 30s..."
  sleep 30
done

# Sefsigned Certificates are not trusted by default
# https://microk8s.io/docs/ssl-certs
# https://collabnix.com/installing-prometheus-on-microk8s-in-2025-a-step-by-step-guide/
kubectl get secret \
    -n cert-manager k8s-root-secret \
    -o jsonpath="{.data.ca\.crt}" | base64 -d > /var/snap/microk8s/current/certs/k8s-root-secret.crt
# Copy the CA certificate to the system's trusted CA store
echo "Copying CA certificate to system's trusted CA store..."
sudo mkdir -p /usr/local/share/ca-certificates/
sudo cp /var/snap/microk8s/current/certs/k8s-root-secret.crt /usr/local/share/ca-certificates/
sudo cp /var/snap/microk8s/current/certs/ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates

echo "CA resources applied successfully."
