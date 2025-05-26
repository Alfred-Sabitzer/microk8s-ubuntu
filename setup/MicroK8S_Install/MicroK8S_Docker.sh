#!/bin/bash
############################################################################################
#
# Configure Docker Repos for MicroK8s
#
# This script sets up trusted Docker repositories for MicroK8s.
# It creates necessary directories and writes configuration files
# to allow MicroK8s to pull images from specified Docker registries.
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
shopt -o -s nounset #- No Variables without definition

# Create directory for Docker certificates
sudo mkdir --parents /var/snap/microk8s/current/args/certs.d/docker.io

# Configure Docker Hub as a trusted repository
cat <<EOF | sudo tee /var/snap/microk8s/current/args/certs.d/docker.io/hosts.toml
server = "https://docker.io"

[host."https://registry-1.docker.io"]
  capabilities = ["pull", "resolve"]
EOF

# Add additional trusted Docker repositories as needed
# Example for a custom Docker repository
sudo mkdir --parents /var/snap/microk8s/current/args/certs.d/docker.slainte.at
cat <<EOF | sudo tee /var/snap/microk8s/current/args/certs.d/docker.slainte.at/hosts.toml
server = "https://docker.slainte.at"

[host."https://docker.slainte.at"]
  capabilities = ["pull", "resolve"]
EOF

# Now you can use your configured Docker repositories with MicroK8s
# Ensure to restart MicroK8s if necessary to apply changes
#