#!/bin/bash
############################################################################################
#
# Stop all Ceph services
# https://forum.proxmox.com/threads/removing-ceph-completely.62818/
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
shopt -o -s nounset #-No Variables without definition

echo "$0 $1"
while IFS=" " read LINE l1 l2; do
 echo "sudo systemctl stop $LINE"
 sudo systemctl stop "$LINE" || true
done < <(systemctl list-unit-files ${1}* | grep -v UNIT)
#
