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
pod=$(kubectl get pods -n slainte | awk '{print $1}'  | grep -i servemux)
podip=$(kubectl get pods -n slainte ${pod} -o jsonpath='{.status.podIP}')

curl http://${podip}/users
#[{"id":"1","name":"bob"}]

curl http://${podip}/users/1
#{"id":"1","name":"bob"}

curl -X POST -H 'content-type: application/json' --data '{"id": "2", "name": "karen"}' http://${podip}/users
#{"id":"2","name":"karen"}

curl http://${podip}/users
#[{"id":"1","name":"bob"},{"id":"2","name":"karen"}]

curl http://${podip}/users/2
#{"id":"2","name":"karen"}

# Test Service
serviceip=$(kubectl get services -n slainte servemux | grep -v CLUSTER | awk '{print $3}')
curl http://${serviceip}/users
#[{"id":"1","name":"bob"},{"id":"2","name":"karen"}]