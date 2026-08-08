#!/bin/bash
############################################################################################
#
# Verify the contents of a PKCS#12 (.p12) file.
#
############################################################################################
#shopt -o -s errexit #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace  #—Displays each command before it is executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <file.p12>"
  exit 1
fi

FILE="$1"

if [ ! -f "$FILE" ]; then
  echo "Error: PKCS#12 file not found: $FILE"
  exit 1
fi

openssl pkcs12 -info -in "$FILE"
