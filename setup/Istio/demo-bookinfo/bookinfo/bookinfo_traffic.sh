#!/bin/bash
################################################################################
#
# create traffic for Istio demo application in MicroK8s.
#
################################################################################
shopt -o -s errexit   #—Terminates  the shell script if a command returns an error code.
#shopt -o -s xtrace    #—Displays each command before it is executed.
shopt -o -s nounset   #-No Variables without definition
set -euo pipefail

NOCURL=${1:-200}
for i in $(seq 1 ${NOCURL}); do 
    myurl=$(echo "http://${K8S_ENVIRONMENT}.http.slainte.at" | envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))")
    curl -s -o /dev/null  ${myurl}
done

