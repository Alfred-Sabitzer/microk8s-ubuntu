#!/bin/bash
############################################################################################
#
# Definition of common names
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition
export registry_k8s="registry.$(hostname --long).slainte.at"
#