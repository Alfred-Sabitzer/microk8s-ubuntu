#!/usr/bin/env bash
############################################################################################
# Check Certificates
#
############################################################################################
#shopt -o -s errexit #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace  #—Displays each command before it is executed.
#shopt -o -s nounset #-No Variables without definition

FILE="$1"

openssl pkcs12 \
    -info \
    -in "$FILE"