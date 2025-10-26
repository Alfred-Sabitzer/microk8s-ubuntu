#!/bin/bash
############################################################################################
#
# Modifikations for external ceph cluster
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
shopt -o -s nounset #- No Variables without definition

sudo modprobe rbd
sudo modprobe nbd
sudo modprobe ceph

# https://github.com/canonical/microk8s/issues/4362
# To make it persistent you need to add to the file, the recommended linux way is to have one file per module for some reason:

echo rbd | sudo tee -a /etc/modules-load.d/rbd.conf
echo nbd | sudo tee -a /etc/modules-load.d/nbd.conf
echo ceph | sudo tee -a /etc/modules-load.d/ceph.conf
sudo chmod 777 /etc/modules-load.d/rbd.conf
sudo chmod 777 /etc/modules-load.d/nbd.conf
sudo chmod 777 /etc/modules-load.d/ceph.conf

#