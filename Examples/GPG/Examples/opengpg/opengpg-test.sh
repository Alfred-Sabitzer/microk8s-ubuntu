#!/bin/bash
############################################################################################
# Test Running Service
############################################################################################
#shopt -o -s errexit	#—Terminates  the shell	script if a	command	returns	an error code.
shopt -o -s xtrace	#—Displays each	command	before it’s	executed.
shopt -o -s nounset	#-No Variables without definition
shopt -s dotglob # Use shopt -u dotglob to exclude hidden directories
IFS="
"

#test pod
pod=$(kubectl get pods -n slainte | awk '{print $1}'  | grep -i opengpg)

kubectl exec ${pod} -n slainte -- /bin/sh -c "ls -lisa"
kubectl exec ${pod} -n slainte -- /bin/sh -c "./opengpg"
kubectl exec ${pod} -n slainte -- /bin/sh -c "ls -lisa"
#