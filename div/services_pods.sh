#!/bin/bash
############################################################################################
# Ausgabe aller Services mit Pods
############################################################################################
shopt -o -s errexit   #—Terminates  the shell script if a command returns an error code.
#shopt -o -s xtrace    #—Displays each command before it’s executed.
shopt -o -s nounset   #-No Variables without definition
IFS=" "
while read NAMESPACE NAME TYPE CLUSTER_IP EXTERNAL_IP   
do
    jt=$(kubectl get service -n ${NAMESPACE} ${NAME} -o jsonpath='{.spec.selector}')
    jt="$(echo ${jt} | sed 's/{//' | sed 's/}//' | sed 's/,.*$//' | sed 's/:/=/g' | sed 's/\"//g')"
    echo "Service: ${NAMESPACE} - ${NAME} hat folgende Pods:"
    kubectl get pod -n ${NAMESPACE} --selector=${jt}   
done < <(kubectl get services --all-namespaces | grep -v NAME )
exit

