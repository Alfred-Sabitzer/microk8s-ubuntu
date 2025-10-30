#!/bin/bash
############################################################################################
# Delete stuck namespace
# See https://faun.pub/kubernetes-namespace-stuck-in-terminating-heres-how-to-clean-it-up-properly-2a1220f170ed
############################################################################################
shopt -o -s errexit   #—Terminates  the shell script if a command returns an error code.
#shopt -o -s xtrace    #—Displays each command before it’s executed.
shopt -o -s nounset   #-No Variables without definition
IFS=" "
mynamespace="istio-system"
while read api
do
    echo "Checking $api in namespace ${mynamespace}..."
    while read NAMEITEM AGE
    do
        echo "deleting ${NAMEITEM}"
        # patch finalizers:
        kubectl patch ${api}/${NAMEITEM} -n ${mynamespace} \
            -p '{"metadata":{"finalizers":[]}}' --type=merge
        # Remove Namespace Finalizers
        #kubectl get namespace ${mynamespace} -o json \
        #| jq 'del(.spec.finalizers)' \
        #| kubectl replace --raw "/api/v1/namespaces/${mynamespace}/finalize" -f -
        # Clean Up Stuck Resources
        echo "kubectl delete ${api} -n ${mynamespace} ${NAMEITEM}"
        kubectl delete ${api} -n ${mynamespace} ${NAMEITEM}
    done < <(kubectl get -n ${mynamespace} $api --ignore-not-found  | grep -v NAME )
done < <(kubectl api-resources --verbs=list --namespaced -o name | grep -v NAME )

exit

