#!/bin/bash
############################################################################################
#
# Install MicroCloud
# https://documentation.ubuntu.com/microcloud/stable/microcloud/how-to/install/
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
shopt -o -s nounset #- No Variables without definition

# Get the directory of the current script
indir=$(dirname "$0")

# Copy configuration file
ansible-playbook -v microcloud_install.yaml 
#
# Install MicroCloud on all nodes
# do this manually
# This is noninteracrtive
#
cat microcloud.yaml | sudo microcloud preseed

# Check Cluster
lxc cluster list
sudo microcloud cluster list
sudo microceph cluster list
sudo microovn cluster list

lxc storage list

lxc storage info remote
lxc storage info remote-fs

lxc network list
lxc network info br-int
lxc network info eno1
lxc network info lxdfan0 

lxc profile list
lxc profile show default

# Check MicroCloud Version
sudo microcloud --version
# Check MicroCeph Version
sudo microceph --version
# Check MicroOVN Version
sudo microovn --version
# Check LXD Version
lxd --version

# MicroK8s is installed and ready for use
echo "MicroCloud installation completed successfully."