#!/bin/bash
############################################################################################
#
# Install MicroCloud - This has to be done on all nodes
# This script installs MicroCloud using the snap package manager.
# https://documentation.ubuntu.com/microcloud/stable/microcloud/how-to/install/
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
shopt -o -s nounset #- No Variables without definition

# Check Versions
#sudo snap info lxd 
#sudo snap info microceph
#sudo snap info microovn 
#sudo snap info microcloud 

ansible all -m shell -a 'sudo snap install lxd --channel=5.21/stable --cohort="+"'
ansible all -m shell -a 'sudo snap install microceph --channel=squid/stable --cohort="+"'
ansible all -m shell -a 'sudo snap install microovn --channel=24.03/stable --cohort="+"'
ansible all -m shell -a 'sudo snap install microcloud --channel=2/stable --cohort="+"'
ansible all -m shell -a 'sudo snap refresh --hold lxd microceph microovn microcloud'

# For Disk Encryption
ansible all -m shell -a 'sudo snap connect microceph:dm-crypt'
ansible all -m shell -a 'sudo snap restart microceph.daemon'


# MicroK8s is installed and ready for use
echo "MicroCloud installation on all Nodes completed successfully."