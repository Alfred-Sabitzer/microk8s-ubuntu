#!/bin/bash
############################################################################################
# Instance Generator
############################################################################################
#shopt -o -s errexit # Terminates  the shell script if a command returns an error code.
#shopt -o -s xtrace  # Displays each command before it is executed.
shopt -o -s nounset  # No Variables without definition

#######
# Generate all the images
#######
md=$(pwd)
cd ansible
./ansible_instancegenerator.sh
cd ${md}
cd demoalpine
./demoalpine_instancegenerator.sh
cd ${md}
cd demodirectory
./demodirectory_instancegenerator.sh
cd ${md}
cd demoreplace
./demoreplace_instancegenerator.sh
cd ${md}
cd demostandard
./demostandard_instancegenerator.sh
cd ${md}
cd ubuntudesktop
./ubuntudesktop_instancegenerator.sh
cd ${md}
#