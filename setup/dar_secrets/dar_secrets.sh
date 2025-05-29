#!/bin/bash
############################################################################################
#
# Enanble Securita for Secrets Data at Rest based on 
#
# https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/
# https://devshell.io/kubernetes-secrets-in-microk8s
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
  echo "Error: microk8s is not installed. Please install microk8s first."
  exit 1
fi

echo "Creating encryption key for secrets..."
# Generate a random 32-byte key and encode it in base64
ek=$(head -c 32 /dev/urandom | base64)

cat <<EOF | sudo tee /var/snap/microk8s/current/args/encryption-config
---
#
# Configuration for Encryption at Rest in MicroK8S
# This file is used to configure the encryption of secrets and configmaps in MicroK8S.
# The encryption key is generated randomly and stored in the file.
#
# See https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/
#
# KMS V2 is not supported in MicroK8S, so we use a simple encryption configuration.
# This configuration uses the secretbox and aescbc providers for encryption.
# The secretbox provider uses a 32-byte key for encryption, while the aescbc provider
# uses a 32-byte key for encryption as well.
# The identity provider is used for plain text storage, which means no encryption.
# Note: This configuration does not provide data confidentiality, as the identity provider
# is included. It is recommended to use a secure encryption provider for production environments. 
# The secret must be a base64-encoded 32-byte key.
#
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
      - secrets
      - configmaps
    providers:
      # This configuration does not provide data confidentiality. The first
      # configured provider is specifying the "identity" mechanism, which
      # stores resources as plain text.
      #
      - secretbox:
          keys:
          - name: k8s-secretbox
          # The secret must be a base64-encoded 32-byte key.
          # This key is used for encrypting secrets.
            secret: ${ek}
      - aescbc:
          keys:
          - name: k8s-aescbc
            # this is just for already existing secrets
            # The secret must be a base64-encoded 32-byte key.
            # This key is used for encrypting secrets.
            secret: ${ek}
      - identity: {} # plain text, in other words NO encryption
---
EOF

# Check if the encryption configuration file was created successfully
if [ ! -f /var/snap/microk8s/current/args/encryption-config ]; then
  echo "Error: Encryption configuration file was not created successfully."
  exit 1
fi

echo "Applying encryption configuration..."

# Remove any existing encryption provider config line from the args file
sudo sed -i '/^--encryption-provider-config.*/d' /var/snap/microk8s/current/args/kube-apiserver
# Insert the new encryption provider config line
sudo sed -i -e '$a\'$'\n''--encryption-provider-config=/var/snap/microk8s/current/args/encryption-config' /var/snap/microk8s/current/args/kube-apiserver
# Enable automatic reload of the encryption provider config
# This line ensures that the kube-apiserver will automatically reload the encryption provider config when it changes
sudo sed -i -e '$a\'$'\n''--encryption-provider-config-automatic-reload=true' /var/snap/microk8s/current/args/kube-apiserver


# Stop and start microk8s to apply the changes
${indir}/../MicroK8S_Stop.sh
${indir}/../MicroK8S_Start.sh


# Encrypt existing secrets
echo "Encrypting existing secrets..."
# This command retrieves all secrets in all namespaces and replaces them with the encrypted version
kubectl get secrets --all-namespaces -o json | kubectl replace -f -
if [ $? -ne 0 ]; then
  echo "Error: Failed to apply encryption configuration."
  exit 1
fi 

echo "Encryption configuration applied successfully."
echo "Checking if required addons are enabled..."
#