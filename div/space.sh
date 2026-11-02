#!/bin/bash
############################################################################################
# find out the disk space usage of the root filesystem and its subdirectories
############################################################################################
shopt -o -s errexit   #—Terminates  the shell script if a command returns an error code.
#shopt -o -s xtrace    #—Displays each command before it is executed.
shopt -o -s nounset   #-No Variables without definition
#
df -h
sudo du -xhd1 / 2>/dev/null | sort -hr
