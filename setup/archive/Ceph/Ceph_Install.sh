#!/bin/bash
############################################################################################
#
# htps://docs.ceph.com/en/reef/
# https://docs.ceph.com/en/reef/cephadm/install/#cephadm-deploying-new-cluster
#
# This has to be done on all nodes
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
#shopt -o -s nounset #-No Variables without definition

#ansible all -m shell -a 'sudo mkdir -p /home/cephadm/.ssh'
ansible all -m shell -a 'sudo mkdir -p /var/log/ceph/'

ansible all -m shell -a 'wget -q -O- "https://download.ceph.com/keys/release.asc2" | sudo apt-key add -'
ansible all -m shell -a 'sudo apt-get update -y'
ansible all -m shell -a 'sudo apt-get install -y net-tools'
ansible all -m shell -a 'sudo apt-get install cryptsetup cryptsetup-initramfs -y'
ansible all -m shell -a 'sudo apt-get -y install podman python3 python3-pip '
ansible all -m shell -a 'sudo apt-get install -y cephadm ceph-common ceph-volume radosgw'
ansible all -m shell -a 'sudo cephadm version || true'
#ansible all -m shell -a 'ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""'
# Distribute server certificates
ansible-playbook -v ceph_cert_dist.yaml 
# Bootstrap-key
ansible all -m shell -a 'sudo mkdir -p /var/lib/ceph/bootstrap-osd'
ansible all -m shell -a 'sudo ln -s /etc/ceph/ceph.client.admin.keyring /var/lib/ceph/bootstrap-osd/ceph.keyring'
ansible all -m shell -a 'sudo ls -lisa /var/lib/ceph/bootstrap-osd/'

# Distribute the SSH key to all nodes
# Holen der public keys
# Verteilen der public keys
ansible all -m authorized_key -a 'user=alfred key="{{ lookup("file", "/home/alfred/.ssh/id_rsa.pub") }}" state=present'