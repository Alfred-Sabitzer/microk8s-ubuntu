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

# apparmor config
# https://bobcares.com/blog/lxc-disable-apparmor/
# lxc config set a1 raw.lxc “lxc.apparmor.profile=unconfined”


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



    1  apt-get install nano
    2  nano /etc/netplan/50-cloud-init.yaml 
    3  cat /etc/netplan/50-cloud-init.yaml 
    4  ip -a addr
    5  netplan apply
    6  ip -a addr
    7  fdisk /dev/nvme0n1
    8  fdisk -h
    9  df -h
   10  cat /etc/fstab 
   11  ls /dev/disk/by-path/
   12  mkdir /data
   13  mount /dev/nvme0n1p3 /data
   14  lsblk -o NAME,FSTYPE,LABLE,SIZR,MOUNTPOINT
   15  lsblk -o NAME,FSTYPE,LABEL,SIZR,MOUNTPOINT
   16  lsblk -o NAME,FSTYPE,LABEL,SIZE,MOUNTPOINT
   17  mount -t auto -v /dev/nvme0n1p3 /data
   18  mount -t ext4 -v /dev/nvme0n1p3 /data
   19  lsblk
   20  blkid /dev/nvme0n1p3
   21  fds
   22  fdisk -lu
   23  pvcreate /dev/nvme0n1p3
   24  df -h
   25  pvs
   26  pvdisplay
   27  vgcreate vg00 /dev/nvme0n1p3
   28  pvdisplay
   29  vgdisplay
   30  lvcreate -n data -l100%VG vg00
   31  df -h
   32  lvdisplay
   33  history > x.txt



