#!/bin/bash
############################################################################################
#
# Check Encryption of Secrets
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

echo "Checking if encryption is already enabled for secrets..."
if ! grep -q -- '--encryption-provider-config=/var/snap/microk8s/current/args/encryption-config' /var/snap/microk8s/current/args/kube-apiserver; then
  echo "Encryption for secrets is NOT enabled."
  exit 1
fi

# Define the backend directory
# This is where the encryption keys and other data are stored
dbdir="/var/snap/microk8s/current/var/kubernetes/backend"


# Check if the encryption configuration file exists
if [ ! -f /var/snap/microk8s/current/args/encryption-config ]; then
  echo "Error: Encryption configuration file does not exist. Please run the setup script first."
  exit 1
fi

# Check if the backend directory exists
if [ ! -d ${dbdir} ]; then
  echo "Error: Backend directory does not exist. Please ensure microk8s is installed correctly."
  exit 1
fi

# Check if the backend directory is writable
if [ ! -w ${dbdir} ]; then
  echo "Error: Backend directory is not writable. Please check permissions."
  exit 1
fi

echo "Encryption for secrets is enabled. Proceeding with test secret creation..."
# Create a test secret to verify encryption
echo "Creating testsecret to verify encryption..."

cat <<EOF > /tmp/test_secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: testsecret
  namespace: default
type: Opaque
data:
  testkey: $(echo -n "testvalue" | base64)
EOF

# Apply the test secret
kubectl apply -f /tmp/test_secret.yaml
# Check if the test secret was created successfully
if ! kubectl get secret testsecret -n default -o jsonpath='{.data.testkey}' | grep -q "$(echo -n "testvalue" | base64)"; then
  echo "Error: Failed to create test secret."
  exit 1
fi
echo "Test secret created successfully. Proceeding with encryption configuration..."

echo "Encryption configuration applied successfully."
echo "Checking if required addons are enabled..."

value=$(cat <<EOF | sudo /snap/microk8s/current/bin/dqlite -c ${dbdir}/cluster.crt  -k ${dbdir}/cluster.key -s localhost:19001 k8s 
select value from kine where name = "/registry/secrets/default/testsecret"
EOF
)

# Decodde the secret value
echo "$value" | awk '{
  for(i=1; i<=NF; i++)
    if ($i > 31 && $i < 127 || $i == 10)
      printf("%c", $i);
    else
      printf(" ", $i);
  print "";
}'
# Check if the test secret is encrypted
if echo "$value" | grep -q "testvalue"; then
  echo "Error: Test secret is NOT encrypted."
  exit 1
fi
echo "Test secret is encrypted successfully."
# Clean up the test secret
kubectl delete -f /tmp/test_secret.yaml
rm -f /tmp/test_secret.yaml
# Check if the test secret was deleted successfully
if [ $? -ne 0 ]; then
  echo "Error: Failed to delete test secret."
  exit 1
fi
#