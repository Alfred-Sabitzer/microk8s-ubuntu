#!/bin/bash
############################################################################################
#
# Create CA for internal use in MicroK8s
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
#shopt -o -s errexit #—Terminates  the shell script if a command returns an error code.
#shopt -o -s nounset #-No Variables without definition
#shopt -o -s xtrace  #—Displays each command before it is executed.
set -euo pipefail

indir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

error() {
  echo "Error: $*" >&2
  exit 1
}

do_cert() {
  cert_name="$1"
  echo "Processing certificate: ${cert_name}"
  sudo rm -f "/var/snap/microk8s/current/certs/${cert_name}.crt"
  if sudo microk8s kubectl get secret -n cert-manager "${cert_name}" -o jsonpath="{.data.ca\.crt}" \
      | base64 -d | sudo tee "/var/snap/microk8s/current/certs/${cert_name}.crt" >/dev/null; then
    sudo chmod 640 "/var/snap/microk8s/current/certs/${cert_name}.crt"
    sudo chown root:microk8s "/var/snap/microk8s/current/certs/${cert_name}.crt"
    sudo cp "/var/snap/microk8s/current/certs/${cert_name}.crt" /usr/local/share/ca-certificates/
  else
    echo "Warning: could not extract secret ${cert_name}; skipping."
  fi
}


if ! command -v sudo >/dev/null 2>&1; then
  error "sudo is not installed."
fi

if ! sudo microk8s kubectl version --client >/dev/null 2>&1; then
  error "sudo microk8s kubectl is not available. Ensure MicroK8s is installed and enabled."
fi

if [ ! -f "${indir}/ca.yaml" ]; then
  error "ca.yaml not found in ${indir}."
fi

echo "Applying CA resources from ${indir}/ca.yaml..."
until sudo microk8s kubectl apply -f "${indir}/ca.yaml"; do
  echo "Retrying apply in 30s..."
  sleep 30
 done

echo "Refreshing CA certificate secrets from cert-manager..."
sudo mkdir -p /usr/local/share/ca-certificates/

do_cert "k8s-intermediate-ca-secret"
do_cert "k8s-root-ca-secret"

# mapfile -t secret_names < <(grep -E '^[[:space:]]*secretName:' "${indir}/ca.yaml" | awk '{print $2}' | sort -u)
# if [ ${#secret_names[@]} -eq 0 ]; then
#   echo "Warning: no secretName entries found in ${indir}/ca.yaml."
# fi
#
# for secret_name in "${secret_names[@]}"; do
#   echo "Processing secret: ${secret_name}"
#   sudo rm -f "/var/snap/microk8s/current/certs/${secret_name}.crt"
#   if sudo microk8s kubectl get secret -n cert-manager "${secret_name}" -o jsonpath="{.data.ca\.crt}" \
#       | base64 -d | sudo tee "/var/snap/microk8s/current/certs/${secret_name}.crt" >/dev/null; then
#     sudo chmod 640 "/var/snap/microk8s/current/certs/${secret_name}.crt"
#     sudo chown root:microk8s "/var/snap/microk8s/current/certs/${secret_name}.crt"
#     sudo cp "/var/snap/microk8s/current/certs/${secret_name}.crt" /usr/local/share/ca-certificates/
#   else
#     echo "Warning: could not extract secret ${secret_name}; skipping."
#   fi
# done

if [ -f /var/snap/microk8s/current/certs/ca.crt ]; then
  sudo cp /var/snap/microk8s/current/certs/ca.crt /usr/local/share/ca-certificates/
fi

echo "Current certificates in /var/snap/microk8s/current/certs:"
sudo ls -1 /var/snap/microk8s/current/certs/

echo "Updating system trusted CA store..."
sudo update-ca-certificates

echo "CA resources applied successfully."
