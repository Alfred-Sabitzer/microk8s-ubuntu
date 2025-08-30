#!/bin/bash
############################################################################################
#
# Install Minimal Ubuntu Noble
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
shopt -o -s nounset #- No Variables without definition

app="UbuntuNobleMinimaldm"

lxc list
lxc delete $app --force
lxc init ubuntu-minimal:noble $app < $app.yaml
lxc start $app
lxc list $app

echo "$app Installed"