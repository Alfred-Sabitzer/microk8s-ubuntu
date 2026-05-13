#!/bin/bash
############################################################################################
#
# Install LXC Macvlan Profile
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
shopt -o -s nounset #- No Variables without definition

# https://luppeng.wordpress.com/2023/01/10/make-lxd-containers-visible-on-host-network/
# https://blog.simos.info/how-to-make-your-lxd-containers-get-ip-addresses-from-your-lan-using-a-bridge/

lxc profile delete macvlan-profile
lxc profile create macvlan-profile < macvlan.yaml
