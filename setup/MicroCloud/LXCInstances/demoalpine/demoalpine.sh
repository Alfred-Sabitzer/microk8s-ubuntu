#!/bin/bash
############################################################################################
# Install demoalpine
# https://documentation.ubuntu.com/lxd/latest/howto/instances_create/
# Images are from https://images.lxd.canonical.com/
# see as well https://documentation.ubuntu.com/lxd/latest/howto/images_manage/
# and https://documentation.ubuntu.com/lxd/latest/howto/images_remote/
############################################################################################
#shopt -o -s errexit # Terminates  the shell script if a command returns an error code.
#shopt -o -s xtrace  # Displays each command before it is executed.
shopt -o -s nounset  # No Variables without definition
app="demoalpine"
lxc list ${app}
lxc delete ${app} --force
lxc init images:alpine/edge/cloud ${app} < ${app}.yaml
lxc start ${app}
lxc list ${app}
echo "${app} Installed"
