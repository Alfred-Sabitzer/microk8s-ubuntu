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

echo "Checking if sudo microk8s is installed..."
if ! command -v sudo microk8s &> /dev/null; then
  echo "Error: sudo microk8s is not installed. Please install sudo microk8s first."
  exit 1
fi


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
# Set proper permissions
sudo chown root:microk8s /var/snap/microk8s/current/args/kube-apiserver
sudo chmod 660 /var/snap/microk8s/current/args/kube-apiserver
sudo chown root:microk8s /var/snap/microk8s/current/args/encryption-config
sudo chmod 660 /var/snap/microk8s/current/args/encryption-config


# Stop and start sudo microk8s to apply the changes
${indir}/../MicroK8S_Stop.sh
${indir}/../MicroK8S_Start.sh


# Encrypt existing secrets
echo "Encrypting existing secrets..."
# This command retrieves all secrets in all namespaces and replaces them with the encrypted version
sudo microk8s.kubectl get secrets --all-namespaces -o json | kubectl replace -f -
if [ $? -ne 0 ]; then
  echo "Error: Failed to apply encryption configuration."
  exit 1
fi 

cat <<EOF
#############################################################################################
#
# Encryption configuration applied successfully.
# Please check encryption with dar_secrets_check.sh
# 
#############################################################################################
EOF
#