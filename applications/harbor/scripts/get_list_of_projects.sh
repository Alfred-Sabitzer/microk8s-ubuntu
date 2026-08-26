#!/bin/bash
############################################################################################
#
# Get List of Projects from Harbor https://github.com/goharbor/harbor/discussions/17426
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
shopt -o -s nounset #-No Variables without definition
curl --cert /etc/containers/certs.d/harbor.test.slainte.at/client.cert \
    --key /etc/containers/certs.d/harbor.test.slainte.at/client.key \
    --cacert /etc/containers/certs.d/harbor.test.slainte.at/ca.crt  \
    -k -X 'GET' \
    'https://harbor.test.slainte.at/api/v2.0/projects?page=1&page_size=10&with_detail=true' \
    -H 'authorization: Basic "${HARBOR_USER}:${HARBOR_PASSWORD}"' \
    -H 'accept: application/json'
