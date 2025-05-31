#!/bin/sh
# connect into container
namespace="default"
podname="bbrook"
mypod=$(kubectl get pod -n ${namespace} | grep -i ${podname} | awk '{print $1 }')
kubectl exec -i -t -n ${namespace} ${mypod} -c ${podname} "--" sh -c "clear; (bash || ash || sh)"