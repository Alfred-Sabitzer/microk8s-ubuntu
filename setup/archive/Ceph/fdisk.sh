#!/bin/bash
############################################################################################
#
# Fdisk Commandos
#
############################################################################################
# delete partition 4
sudo lsblk
echo "Deleting partition 4 on /dev/nvme0n1..."
sudo fdisk /dev/nvme0n1 << EOF
p
d
4
p
w
EOF
sudo lsblk
# create partition 4
echo "Creating partition 4 on /dev/nvme0n1..."
sudo fdisk /dev/nvme0n1 << EOF 
p
n
4


Y
p
w
EOF
sudo lsblk
#
