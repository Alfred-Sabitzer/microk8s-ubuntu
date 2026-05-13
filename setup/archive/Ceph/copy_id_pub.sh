#!/bin/bash
############################################################################################
#
# Distribute public SSH key to all nodes using Ansible.
# Usage: ./copy_id_pub.sh
# Prerequisites: ansible installed, passwordless sudo, SSH keys generated.
#
############################################################################################
set -euo pipefail

# Check for required commands
for cmd in ansible ansible-playbook; do
  if ! command -v $cmd &> /dev/null; then
    echo "Error: $cmd is not installed."
    exit 1
  fi
done

# Validate required files
if [ ! -f "/home/alfred/.ssh/id_rsa.pub" ]; then
  echo "Error: Public key /home/alfred/.ssh/id_rsa.pub not found."
  exit 1
fi
if [ ! -f "copy_id_pub.yaml" ]; then
  echo "Error: copy_id_pub.yaml not found."
  exit 1
fi

echo "Running Ansible playbook to fetch public keys..."
ansible-playbook -v copy_id_pub.yaml

echo "Listing fetched public keys..."
ls -lisa /home/alfred/tmp/

for host in k1.slainte.at k2.slainte.at k3.slainte.at k4.slainte.at; do
  key_file="/home/alfred/tmp/${host}.pub"
  if [ ! -f "$key_file" ]; then
    echo "Warning: $key_file not found, skipping."
    continue
  fi
  echo "Adding public key for $host..."
  ansible all -m authorized_key -a "user=alfred key='{{ lookup(\"file\", \"$key_file\") }}' state=present"
done

echo "SSH key distribution complete."
