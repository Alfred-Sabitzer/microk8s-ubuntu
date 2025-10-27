#!/bin/bash
############################################################################################
#
# configuration of microk8s nodes
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
shopt -o -s nounset #-No Variables without definition
#
# Define aliase
#
sudo sed -i '/# MicroK8s physical nodes/d' /etc/hosts
sudo sed -i '/micro1.slainte.at/d' /etc/hosts
sudo sed -i '/micro2.slainte.at/d' /etc/hosts
sudo sed -i '/micro3.slainte.at/d' /etc/hosts
sudo sed -i '/micro4.slainte.at/d' /etc/hosts
sudo sed -i '/ceph.micro4.slainte.at/d' /etc/hosts
sudo sed -i '/ceph.slainte.at/d' /etc/hosts
sudo sed -i '/omv.slainte.at/d' /etc/hosts
sudo sed -i '/ceph.micro4.slainte.at/d' /etc/hosts
cat << EOF | sudo tee -a /etc/hosts
# MicroK8s physical nodes
192.168.0.191 micro1.slainte.at micro1
192.168.0.192 micro2.slainte.at micro2
192.168.0.193 micro3.slainte.at micro3
192.168.0.194 micro4.slainte.at micro4
192.168.0.194 ceph.micro4.slainte.at ceph
192.168.0.10  omv.slainte.at omv
EOF
#
