#!/bin/sh
# connect into container
namespace="openbao"
podname="openbao"
mypod=$(sudo kubectl get pod -n ${namespace} | grep -i ${podname} | awk '{print $1 }')
sudo kubectl exec -i -t -n ${namespace} ${mypod} -c ${podname} "--" sh -c "clear; (bash || ash || sh)"
