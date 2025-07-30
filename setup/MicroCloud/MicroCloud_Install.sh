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

sudo microcloud init

# Add Disk (has to be done on all nodes)
sudo microceph disk add /dev/nvme0n1p4 --wipe --encrypt

# Local Disks (to be done on all nodes)
sudo lxc storage volume create disks /dev/nvme0n1p3 --type block


# Check Cluster
lxc cluster list
sudo microcloud cluster list
sudo microceph cluster list
sudo microovn cluster list

lxc storage list

lxc storage info pool



# MicroK8s is installed and ready for use
echo "MicroCloud installation completed successfully."