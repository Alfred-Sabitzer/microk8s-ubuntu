#!/bin/bash
############################################################################################
# Ausgabe aller CRD's
############################################################################################
shopt -o -s errexit   #—Terminates  the shell script if a command returns an error code.
#shopt -o -s xtrace    #—Displays each command before it’s executed.
shopt -o -s nounset   #-No Variables without definition
IFS=" "
KUBECTL="sudo microk8s kubectl"
while read NAME CREATED_AT
do
    echo "${NAME}"
    ${KUBECTl} get ${NAME} -o yaml --all-namespaces > ${NAME}.yaml
done < <(${KUBECTl} get customresourcedefinitions.apiextensions.k8s.io  --all-namespaces  | grep -v NAME )
exit

