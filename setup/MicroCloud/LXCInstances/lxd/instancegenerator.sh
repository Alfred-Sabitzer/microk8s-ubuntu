#!/bin/bash
############################################################################################
# Instance Generator
############################################################################################
#shopt -o -s errexit # Terminates  the shell script if a command returns an error code.
#shopt -o -s xtrace  # Displays each command before it is executed.
shopt -o -s nounset  # No Variables without definition

#######
# Master adiministration image
#######
pd="/home/alfred/VSCode/microk8s-ubuntu/setup/MicroCloud/InstanceGenerator"
python3 ${pd}/instancegenerator.py \
    --project=default \
    --profile=desktop \
    --image="ubuntudesktop" \
    --template_dir=${pd}/template \
    --name=lxd
