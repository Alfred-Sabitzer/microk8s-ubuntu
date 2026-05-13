#!/bin/bash
############################################################################################
#
# Prepareation of Disks for Ceph cluster.
#
############################################################################################
set -euo pipefail

#### Rados has to be enabled on the cluster before you can create OSDs. 




sudo ceph orch daemon add osd  $(hostname -s):/dev/$(hostname -s)/$(hostname -s)

# https://docs.ceph.com/en/mimic/ceph-volume/lvm/encryption/
# https://kifarunix.com/how-to-encrypt-data-at-rest-on-ceph-cluster-osd/

# --dmcrypt
lsblk --list


sudo ceph orch device ls --refresh

#AQAm/HxoMxg5CBAAuinYIzlRvQSGNpeYUzEuhA==
mykey=$(sudo ceph auth get-key client.admin --keyring=/etc/ceph/ceph.client.admin.keyring)
sudo ceph-volume lvm create --bluestore --data /dev/nvme0n1p4 --dmcrypt
lsblk --list
sudo ceph orch device ls --refresh
