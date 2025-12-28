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
#shopt -o -s xtrace #—Displays each command before it is executed.
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

sleep 10

sudo mkdir -p /usr/local/share/ca-certificates/
# Delete specific secrets first to avoid dangling resources
echo "Deleting specific secrets ..."
sudo rm -f /usr/local/share/ca-certificates/ca.crt
cat ca.yaml | grep 'secretName:' | awk '{print $2}' |  sort --unique | while read -r secret_name; do
  echo "Refreshing $secret_name ..."
# Cleanup old certificates
  sudo rm -f /var/snap/microk8s/current/certs/$secret_name.crt
# Extract the CA certificate from the Kubernetes secret and save it to a file
# Sefsigned Certificates are not trusted by default
# https://microk8s.io/docs/ssl-certs
# https://collabnix.com/installing-prometheus-on-microk8s-in-2025-a-step-by-step-guide/
  kubectl get secret \
    -n cert-manager $secret_name \
    -o jsonpath="{.data.ca\.crt}" | base64 -d > /var/snap/microk8s/current/certs/$secret_name.crt
# Copy the CA certificate to the system's trusted CA store
  sudo cp /var/snap/microk8s/current/certs/$secret_name.crt /usr/local/share/ca-certificates/
done
sudo cp /var/snap/microk8s/current/certs/ca.crt /usr/local/share/ca-certificates/

sudo chown root:root /usr/local/share/ca-certificates/*.crt
sudo chmod 640 /usr/local/share/ca-certificates/*.crt
sudo chown root:microk8s /var/snap/microk8s/current/certs/*.crt
sudo chmod 640 /var/snap/microk8s/current/certs/*.crt

echo "Current certificates in MicroK8s certs directory:"
ls -list /var/snap/microk8s/current/certs/

echo "Updating CA certificates..."
sudo update-ca-certificates

echo "CA resources applied successfully."
