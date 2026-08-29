#!/bin/bash
############################################################################################
#
# Get the artifacts from Harbor https://github.com/goharbor/harbor/blob/main/api/v2.0/swagger.yaml#L1551
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
shopt -o -s nounset #-No Variables without definition
PAGE=1
      while : ; do
        # Get page # of all registry projects
        PROJECTS=$(curl --cert /etc/containers/certs.d/harbor.test.slainte.at/client.cert \
            --key /etc/containers/certs.d/harbor.test.slainte.at/client.key \
            --cacert /etc/containers/certs.d/harbor.test.slainte.at/ca.crt  \
            -k -X 'GET' "https://harbor.test.slainte.at/api/v2.0/projects?page=${PAGE}&page_size=25&with_detail=true" -H 'authorization: Basic "${HARBOR_USER}:${HARBOR_PASSWORD}"' -H 'accept: application/json')

        let "PAGE++"

        # Exit if no more projects
        if [ $(echo $PROJECTS | jq length) -eq 0 ]; then
          wait
          break
        fi

        echo $PROJECTS
done




applications/harbor/scripts/get_list_of_projects.sh