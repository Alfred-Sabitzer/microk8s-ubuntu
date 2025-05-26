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
#pod=$(kubectl get pods -n slainte | awk '{print $1}'  | grep -i servemux)
#podip=$(kubectl get pods -n slainte ${pod} -o jsonpath='{.status.podIP}')

podip='localhost'
port='8080'

curl http://${podip}:${port} | base64 --decode
#{"Clients":[{"Message":"All messages are base64 encoded"},{"Message":"eg. curl -X POST -H 'content-type: application/json' --data 'eyJDbGllbnRzIjpbeyJNZXNzYWdlIjoiTWVzc2FnZTEifSx7Ik1lc3NhZ2UiOiJNZXNzYWdlMiJ9XX0=' http://localhost/encrypt"}]}

curl http://${podip}:${port}/healthz  | base64 --decode
#{"1":{"version":"2025-03-01","doku":"https://gitlab.com/Alfred-Sabitzer/microk8s-ubuntu/-/tree/master/gpgsecret?ref_type=heads"}}

geheim=$(echo -n "Das ist geheim"  | base64)
message=$(echo -n '{"Message": "'${geheim}'"}')
secret=$(curl -X POST -H 'content-type: application/json' --data "${message}" http://${podip}:${port}/encode)
echo ${secret} | base64 --decode
#-----BEGIN Message-----
#
#wcFMAx4Y4OnP9dXTARAAE6xKhITBXArURosxdAMEbYKW6BjjcW3//lyoIW/xv0hq
#6WJYk5fx3534BY09SLl2DP/HYSZcVPnjdPF/LkmhNvyGFkfql6LbW+TS1q8nXVZp
#1wssSWze/zxnZ2Wh5LFSrn2cx1oa/0CWJ0FuiTBtdBBwFBmVISOwiwWzNoVtWw4w
#1BVPyp25ZOGnQphuDp51nWkppL4eFn0HTwy5j33oyN2UM/+i4dRayYvXJr4vAIRF
#aMsk4RZ/IRemjQj8QMNohfN3ZL0y/iHD6kmhqB00zq8/LhvWEoVG2pQCUnzn7pwA
#/PGUEYYiSf7yEL6TD77XIq+F1YB8btuCjdtUr5o2jJ8L+7yXBvzbl3LAIjrJPqPG
#ibly8PgYu7MZYnmxNyX/+/VX5AX8gLVAFbY2BFBgv7NH8HO5HzaE8qwNZ7jDp79W
#RLUKvm33msB1cR/2YI5sJUqfyY30MjQLPDQA7WM3W10CQ9VPhON8+LPRUuKmENMR
#e/saKlk4ZGJyRIP0GsOvggxywjVCSUhqDTCU3ucPVbRcLn3ZdZO5YpBvz0CqsEBi
#xlnMq0WGMgapDr6KPamDqzgyVBd80Q8TN06Bn8k/l/YeO25KNXEwPOHkKYKy9RO2
#da1+7sH0NwTGGCwUZIFj8hk+wAdSBmBV6BC9JLkQGyTCQJUuPR/PsB9JUAVWbz7S
#5QHBC62p4Qw96N7Yx+NuDo7vCjc2hKl2lkCh7sBAUVj75NeGp5K5czvpRKfjG7gP
#uJDj8WgT9mPaMuXgGwA=
#=tTQo
#-----END Message-----

secretmessage=$(echo -n '{"Message": "'${secret}'"}')
echo $secretmessage
decrypt=$(curl -X POST -H 'content-type: application/json' --data "${secretmessage}" http://${podip}:${port}/decode)

echo ${decrypt}  | base64 --decode
#Das ist geheim
exit

# Test Service
serviceip=$(kubectl get services -n slainte servemux | grep -v CLUSTER | awk '{print $3}')
curl http://${serviceip}/status
#[{"id":"1","name":"bob"},{"id":"2","name":"karen"}]