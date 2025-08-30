#!/bin/bash
############################################################################################
#
# Remove MicroCloud
# https://documentation.ubuntu.com/microcloud/stable/microcloud/how-to/remove/
# https://documentation.ubuntu.com/microcloud/stable/microcloud/how-to/install/
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
shopt -o -s nounset #- No Variables without definition

ansible all -m shell -a 'sudo snap remove lxd microceph microovn microcloud --purge  --terminate '

# Check this manually on each node
sudo lvscan --all
sudo pvs
sudo pvdisplay 
sudo vgdisplay 
sudo lvdisplay
sudo fdisk /dev/nvme0n1



# Remove LVM Volumes
sudo lvremove /dev/vg00/data_snap 
# Remove LVM Physical Volume
sudo pvremove /dev/sde1
# Remove LVM Volume Group
sudo vgremove vg0

# MicroK8s is completely removed
echo "MicroCloud completed removed."