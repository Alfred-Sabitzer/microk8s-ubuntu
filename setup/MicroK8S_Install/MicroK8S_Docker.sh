#!/bin/bash
############################################################################################
#
# Configure Docker Repos
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition

sudo mkdir --parents /var/snap/microk8s/current/args/certs.d/docker.io
cat <<EOF | sudo tee /var/snap/microk8s/current/args/certs.d/docker.io/hosts.toml
server = "https://docker.io"

[host."https://registry-1.docker.io"]
  capabilities = ["pull", "resolve"]
EOF

# Here add you additional trusted docker-repos
# See https://microk8s.io/docs/registry-private

sudo mkdir --parents /var/snap/microk8s/current/args/certs.d/docker.slainte.at
cat <<EOF | sudo tee /var/snap/microk8s/current/args/certs.d/docker.slainte.at/hosts.toml
server = "https://docker.slainte.at"

[host."https:/docker.slainte.at"]
capabilities = ["pull", "resolve"]
EOF

#
# Now you can use your repos
#