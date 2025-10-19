#!/bin/bash
############################################################################################
#
# Create a Ceph filesystem in MicroCeph.
#
# Usage: sudo ./MicroCeph_Pool.sh
# Prerequisites: snap microceph installed, sudo privileges
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
shopt -o -s nounset #-No Variables without definition
set -euo pipefail

# Create CephFS pools and filesystem
sudo microceph.ceph osd pool create cephfs_data
sudo microceph.ceph osd pool set cephfs_data bulk true

sudo microceph.ceph osd pool create cephfs_metadata
# List pools to verify creation
sudo microceph.ceph osd pool ls

# Create Ceph filesystem
sudo microceph.ceph fs new cephfs cephfs_metadata cephfs_data
# List filesystems to verify creation
sudo microceph.ceph df
sudo microceph.ceph fs ls
# Check filesystem status
sudo microceph.ceph mds stat
#

# Create a CephFS pool in LXD
sudo lxc storage create cephfs cephfs source=cephfs --target micro1.slainte.at --target micro2.slainte.at --target micro3.slainte.at --target micro4.slainte.at cephfs.create_missing=true cephfs.data_pool=cephfs_data cephfs.meta_pool=cephfs_metadata

#    --target micro1.slainte.at \
#    --target micro2.slainte.at \
#    --target micro3.slainte.at \
#    --target micro4.slainte.at \

sudo lxc storage create cephfs cephfs --target micro1.slainte.at
sudo lxc storage create cephfs cephfs --target micro2.slainte.at
sudo lxc storage create cephfs cephfs --target micro3.slainte.at
sudo lxc storage create cephfs cephfs --target micro4.slainte.at

sudo lxc storage create cephfs cephfs \
    source=micro1.slainte.at://cephfs \
    cephfs.path=/var/data

sudo lxc storage create cephfs cephfs \
    cephfs.path=/var/data \
    cephfs.data_pool=cephfs_data \
    cephfs.meta_pool=cephfs_metadata

sudo lxc storage create cephfs cephfs source=cephfs/ 
sudo lxc storage create cephfs cephfs source=cephfs/ 

sudo lxc storage create cephfs cephfs cephfs.path=/var/data
    
sudo lxc storage create test cephfs --target micro1.slainte.at
sudo lxc storage create test cephfs --target micro2.slainte.at
sudo lxc storage create test cephfs --target micro3.slainte.at
sudo lxc storage create test cephfs --target micro4.slainte.at
sudo lxc storage create test cephfs \
    source=test \
    cephfs.create_missing=true \
    cephfs.data_pool=test_data \
    cephfs.meta_pool=test_metadata
