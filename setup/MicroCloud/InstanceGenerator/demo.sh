#!/bin/bash
############################################################################################
# Install {name_instance}
# https://documentation.ubuntu.com/lxd/latest/howto/instances_create/
# Images are from https://images.lxd.canonical.com/
# see as well https://documentation.ubuntu.com/lxd/latest/howto/images_manage/
# and https://documentation.ubuntu.com/lxd/latest/howto/images_remote/
############################################################################################
shopt -o -s nounset
app="demo"
lxc list
lxc delete ${app} --force
lxc init ubuntu-minimal:noble ${app} < ${app}.yaml
lxc start ${app}
lxc list ${app}
echo "${app} Installed"
