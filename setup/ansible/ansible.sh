#!/bin/bash
############################################################################################
#
# Install ansible on control-node
#
# https://docs.ansible.com/ansible/latest/getting_started/index.html
# https://docs.ansible.com/ansible/latest/installation_guide/installation_distros.html#installing-ansible-on-ubuntu
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail

# Get the directory of the current script
indir=$(dirname "$0")

# to be done on control-node (this is omv in our case)
sudo apt update
sudo apt install software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install ansible --yes

echo "ansible resources applied successfully."

# configure ansible.cfg
sudo ansible-config init --disabled -t all | sudo tee /etc/ansible.cfg
# Check if ansible.cfg exists
if [ ! -f "/etc/ansible.cfg" ]; then
  echo "Error: ansible.cfg not found in /etc."
  exit 1
fi 

# Add the inventory file
sudo mkdir -p /etc/ansible 
cat <<EOF | sudo tee /etc/ansible/hosts
# k8s.slainte.at

[k8s]
k1.slainte.at
k2.slainte.at
k3.slainte.at 
k4.slainte.at
EOF

if [ ! -f "/etc/ansible/hosts" ]; then
  echo "Error: inventory file not found in ${indir}."
  exit 1
fi

# test
ansible all -m ping
if [ $? -ne 0 ]; then
  echo "Error: Ansible ping test failed."
  exit 1
fi


