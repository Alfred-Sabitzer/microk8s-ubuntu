#!/bin/bash
############################################################################################
#
# htps://docs.ceph.com/en/reef/
# https://docs.ceph.com/en/reef/cephadm/install/#cephadm-deploying-new-cluster
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it’s executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail
indir=$(dirname "$0")

#     Ceph_Install.sh


#You should set a password with usermod -p to unlock this user's password.
#sudo usermod --password PASSWORD cephadm

# Install cephadm
# Ceph Squid 19.2.x *
#CEPH_RELEASE=19.2.2 # replace this with the active release
#cephadm="python3 /usr/sbin/cephadm"

#sudo apt-get -y install python3-cephfs librbd1 python3-rados python3-rbd python3-rgw libcephfs2 libicu70 libldap-2.5-0 librados2 libradosstriper1 libthrift-0.16.0

# Bootstrap the cluster
#if [ -f /etc/ceph/ceph.conf ]; then
#    echo "Ceph is already installed. Exiting."
#    exit 0
#fi

#The --ssh-user *<user>* option makes it possible to designate which SSH user cephadm will use to connect to hosts. The associated SSH key will be added to /home/*<user>*/.ssh/authorized_keys. The user that you designate with this option must have passwordless sudo access.

sudo cephadm bootstrap --mon-ip  $(hostname -I | awk '{print $1}') --allow-fqdn-hostname  --no-cleanup-on-failure --allow-overwrite --ssh-user alfred --ssh-private-key /home/alfred/.ssh/id_rsa --ssh-public-key /home/alfred/.ssh/id_rsa.pub --initial-dashboard-user alfred --initial-dashboard-password alfred

sudo ceph telemetry on --license sharing-1-0
sudo ceph telemetry enable channel perf
sudo ceph status

sudo ceph orch host add k2 192.168.0.192
sudo ceph orch host label add k2 _admin

sudo ceph orch host add k3 192.168.0.193
sudo ceph orch host label add k3 _admin

sudo ceph orch host add k4 192.168.0.194
sudo ceph orch host label add k4 _admin

sudo ceph orch ps k1
sudo ceph orch ps k2
sudo ceph orch ps k3
sudo ceph orch ps k4

#
# Now prepare your disks 
# check /etc/fstab
# delete partitions with fdisk

# alfred@k1:~$ sudo fdisk /dev/nvme0n1
#
# Welcome to fdisk (util-linux 2.39.3).
# Changes will remain in memory only, until you decide to write them.
# Be careful before using the write command.
#
# This disk is currently in use - repartitioning is probably a bad idea.
# It's recommended to umount all file systems, and swapoff all swap
# partitions on this disk.
#
#
# Command (m for help): p
#
# Disk /dev/nvme0n1: 476.94 GiB, 512110190592 bytes, 1000215216 sectors
# Disk model: SAMSUNG MZVLW512HMJP-000H1              
# Units: sectors of 1 * 512 = 512 bytes
# Sector size (logical/physical): 512 bytes / 512 bytes
# I/O size (minimum/optimal): 512 bytes / 512 bytes
# Disklabel type: gpt
# Disk identifier: 30F6DDCB-4A26-4B1D-A6EF-6B8128144B58
#
# Device             Start        End   Sectors   Size Type
# /dev/nvme0n1p1      2048    2203647   2201600     1G EFI System
# /dev/nvme0n1p2   2203648   12689407  10485760     5G Linux filesystem
# /dev/nvme0n1p3  12689408  222404607 209715200   100G Linux filesystem
# /dev/nvme0n1p4 222404608 1000214527 777809920 370.9G Linux filesystem
#
# Command (m for help): m
#
# Help:
#
#   GPT
#    M   enter protective/hybrid MBR
#
#   Generic
#    d   delete a partition
#    F   list free unpartitioned space
#    l   list known partition types
#    n   add a new partition
#    p   print the partition table
#    t   change a partition type
#    v   verify the partition table
#    i   print information about a partition
#
#   Misc
#    m   print this menu
#    x   extra functionality (experts only)
#
#   Script
#    I   load disk layout from sfdisk script file
#    O   dump disk layout to sfdisk script file
#
#   Save & Exit
#    w   write table to disk and exit
#    q   quit without saving changes
#
#   Create a new label
#    g   create a new empty GPT partition table
#    G   create a new empty SGI (IRIX) partition table
#    o   create a new empty MBR (DOS) partition table
#    s   create a new empty Sun partition table
#
# Delete what is there --------------------------------------------------------------------------------------------
#
# Command (m for help): d
# Partition number (1-4, default 4): 4
#
# Partition 4 has been deleted.
#
# Command (m for help): w
# The partition table has been altered.
# Failed to remove partition 4 from system: Device or resource busy
#
# The kernel still uses the old partitions. The new table will be used at the next reboot. 
# Syncing disks.
#
# alfred@k1:~$ A
#
# Create a new partition --------------------------------------------------------------------------------------------
#
#Command (m for help): n
#Partition number (4-128, default 4): 4
#First sector (222404608-1000215182, default 222404608): 
#Last sector, +/-sectors or +/-size{K,M,G,T,P} (222404608-1000215182, default 1000214527): 
#
#Created a new partition 4 of type 'Linux filesystem' and of size 370.9 GiB.
#Partition #4 contains a LVM2_member signature.
#
#Do you want to remove the signature? [Y]es/[N]o: Y
#
#The signature will be removed by a write command.
#
#Command (m for help): w
#The partition table has been altered.
#Syncing disks.
#
#alfred@k1:~$ Check scripts for robustness, documentation and best practice.
#
#
#alfred@k1:~$ lsblk
#NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
#sr0          11:0    1  1024M  0 rom  
#nvme0n1     259:0    0 476.9G  0 disk 
#├─nvme0n1p1 259:1    0     1G  0 part /boot/efi
#├─nvme0n1p2 259:2    0     5G  0 part /boot
#├─nvme0n1p3 259:3    0   100G  0 part /var/lib/containers/storage/overlay
#│                                     /
#└─nvme0n1p4 259:4    0 370.9G  0 part 
#
#alfred@k1:~$ sudo pvcreate /dev/nvme0n1p4
#  Physical volume "/dev/nvme0n1p4" successfully created.
#alfred@k1:~$ sudo vgcreate  $(hostname -s) /dev/nvme0n1p4
#  Volume group "k1" successfully created
#alfred@k1:~$ sudo lvcreate -n $(hostname -s) -l 100%FREE $(hostname -s)
#WARNING: ceph_bluestore signature detected on /dev/k1/k1 at offset 0. Wipe it? [y/n]: y
#  Wiping ceph_bluestore signature on /dev/k1/k1.
#  Logical volume "k1" created.
#alfred@k1:~$ lsblk
#NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
#sr0          11:0    1  1024M  0 rom  
#nvme0n1     259:0    0 476.9G  0 disk 
#├─nvme0n1p1 259:1    0     1G  0 part /boot/efi
#├─nvme0n1p2 259:2    0     5G  0 part /boot
#├─nvme0n1p3 259:3    0   100G  0 part /var/lib/containers/storage/overlay
#│                                     /
#└─nvme0n1p4 259:4    0 370.9G  0 part 
#  └─k1-k1   252:0    0 370.9G  0 lvm  
#alfred@k1:~$ 
#

sudo lsblk
sudo pvcreate /dev/nvme0n1p4
sudo vgcreate  $(hostname -s) /dev/nvme0n1p4
sudo lvcreate -n $(hostname -s) -l 100%FREE $(hostname -s)
sudo lsblk

sudo ceph orch device ls 

#
# OSD are created best within the dashboard
# https://docs.ceph.com/en/reef/cephadm/operations/#osd
#

sudo ceph orch daemon add osd $(hostname -s):/dev/$(hostname -s)/$(hostname -s) --dry-run

#sudo ceph orch daemon add osd k1:/dev/nvme0n1p4  
#sudo ceph orch daemon add osd k1:/dev/my_vg/my_lv 

########################
# alfred@k1:~$ sudo cephadm shell --fsid 041df75e-64b8-11f0-ad20-1860249d59b9
# Inferring config /var/lib/ceph/041df75e-64b8-11f0-ad20-1860249d59b9/mon.k1/config
# Not using image '4892a7ef541bbfe6181ff8fd5c8e03957338f7dd73de94986a5f15e185dacd51' as it's not in list of non-dangling images with ceph=True label
# root@k1:/# ceph
# ceph                         ceph-dencoder                ceph-mds                     ceph-osdomap-tool            cephadm
# ceph-authtool                ceph-diff-sorted             ceph-mgr                     ceph-post-file               cephfs-data-scan
# ceph-bluestore-tool          ceph-erasure-code-tool       ceph-mon                     ceph-rbdnamer                cephfs-journal-tool
# ceph-clsinfo                 ceph-exporter                ceph-monstore-tool           ceph-run                     cephfs-mirror
# ceph-conf                    ceph-fuse                    ceph-node-proxy              ceph-syn                     cephfs-table-tool
# ceph-crash                   ceph-immutable-object-cache  ceph-objectstore-tool        ceph-volume                  cephfs-top
# ceph-create-keys             ceph-kvstore-tool            ceph-osd                     ceph-volume-systemd          
# root@k1:/# ceph-bluestore-tool zap-device --dev /dev/nvme0n1p4 --yes-i-really-really-mean-it
# root@k1:/# 

###################################

#sudo mkdir -p /var/lib/ceph/osd/ceph-1
#
#ceph-volume lvm zap --destroy /dev/nvme0n1p4  
#ceph-volume lvm create --bluestore --data /dev/nvme0n1p4
#sudo ceph-volume lvm zap --destroy /dev/nvme0n1p4  # Destroys any existing LVM data 
#sudo ceph-volume lvm prepare --data /dev/nvme0n1p4 --osd-id 1
#
#sudo ceph orch apply osd --all-available-devices --dry-run

#ceph orch apply osd --all-available-devices
#sudo ceph orch apply mds
#sudo ceph orch apply rgw
#sudo ceph orch apply mgr
#sudo ceph orch apply nfs
#sudo ceph orch apply dashboard
#sudo ceph orch apply mgr dashboard
