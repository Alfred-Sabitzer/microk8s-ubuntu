#!/bin/bash
# clone gitlab repos
echo "Cloning gitlab repos..."
cd /home/ansible/gitlab
rm -rf microk8s-ubuntu/
git clone https://github.com/Alfred-Sabitzer/microk8s-ubuntu.git
cd /home/ansible/scripts
echo "Delete gitlab on Nodes..."
ansible k8s -m shell -a 'rm -rf /home/ansible/gitlab/'
ansible k8s -m shell -a 'mkdir -p /home/ansible/gitlab/'
echo "create tar ..."
tar -czvf /tmp/gitlab.tar.gz -C /home/ansible/gitlab/ .
ansible-playbook -v ./clone_gitlab.yaml