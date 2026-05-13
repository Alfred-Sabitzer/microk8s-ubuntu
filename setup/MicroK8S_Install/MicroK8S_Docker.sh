#!/bin/bash
############################################################################################
#
# Configure Docker Repos for MicroK8s
#
# This script sets up trusted Docker repositories for MicroK8s.
# It creates necessary directories and writes configuration files
# to allow sudo microk8s to pull images from specified Docker registries.
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
shopt -o -s nounset #- No Variables without definition

# Create directory for Docker certificates
# Configure Docker Hub as a trusted repository
sudo mkdir --parents /var/snap/microk8s/current/args/certs.d/docker.io
cat <<EOF | sudo tee /var/snap/microk8s/current/args/certs.d/docker.io/hosts.toml
server = "https://docker.io"

[host."https://registry-1.docker.io"]
  capabilities = ["pull", "resolve"]
EOF

# Environment specific settings - Early phase configuration for registry and letsencrypt settings
if [ "$(hostname | cut -d'-' -f2)" = "k8stest" ]; then
    K8S_ENVIRONMENT="test"
    K8S_LETSENCRYPT="k8s-intermediate-issuer"
else
    K8S_ENVIRONMENT="k8s"
    K8S_LETSENCRYPT="letsencrypt"
fi
export K8S_ENVIRONMENT
export K8S_LETSENCRYPT
export K8S_REGISTRY="registry.${K8S_ENVIRONMENT}.slainte.at"

# Add additional trusted Docker repositories as needed
# Example for a custom Docker repository
sudo mkdir --parents /var/snap/microk8s/current/args/certs.d/${K8S_REGISTRY}
cat <<EOF | sudo tee /var/snap/microk8s/current/args/certs.d/${K8S_REGISTRY}/hosts.toml
server = "https://${K8S_REGISTRY}"

[host."https://${K8S_REGISTRY}"]
  capabilities = ["pull", "resolve"]
EOF

export K8S_HABOR_REGISTRY="habor.${K8S_ENVIRONMENT}.slainte.at"

# Add additional trusted Docker repositories as needed
# Example for a custom Docker repository
sudo mkdir --parents /var/snap/microk8s/current/args/certs.d/${K8S_HABOR_REGISTRY}
cat <<EOF | sudo tee /var/snap/microk8s/current/args/certs.d/${K8S_HABOR_REGISTRY}/hosts.toml
server = "https://${K8S_HABOR_REGISTRY}"

[host."https://${K8S_HABOR_REGISTRY}"]
  capabilities = ["pull", "resolve"]
EOF

# Note: If you have additional private registries, repeat the above steps to add them as trusted repositories.
# Now you can use your configured Docker repositories with MicroK8s
# Ensure to restart sudo microk8s if necessary to apply changes
#