#!/bin/bash
# clone ceph directory to all k8s nodes
echo "Cloning rook dir..."
cd /home/ansible/ceph
rm -rf rook/
git clone https://github.com/rook/rook.git
cd /home/ansible/scripts
echo "Delete ceph on Nodes..."
ansible k8s -m shell -a 'sudo rm -rf /home/ansible/ceph/'
ansible k8s -m shell -a 'sudo mkdir -p /home/ansible/ceph'
ansible k8s -m shell -a 'sudo chown ansible:ansible /home/ansible/ceph'
echo "create tar ..."
tar -czvf /tmp/ceph.tar.gz -C /home/ansible/ceph/ .
ansible-playbook -v ./clone_ceph.yaml