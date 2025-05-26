#!/bin/bash
############################################################################################
# Anzeige der Logs des Containers (local running)
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition
source ./var.sh
#
podman logs ${runname}