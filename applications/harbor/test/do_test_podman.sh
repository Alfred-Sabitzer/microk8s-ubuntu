#!/bin/bash
############################################################################################
#
# build and deploy against public Harbor test
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
shopt -o -s nounset #-No Variables without definition
# Build
build="podman"
tag=$(date +"%Y%m%d")
project="test"
image="dummy"
HARBOR_LINK="harbor.test.slainte.at"
# Cleanup - Only for maintainers, not for developers.
# curl --cert /etc/containers/certs.d/harbor.test.slainte.at/client.cert \
#     --key /etc/containers/certs.d/harbor.test.slainte.at/client.key \
#     --cacert /etc/containers/certs.d/harbor.test.slainte.at/ca.crt  \
#     -X 'DELETE' \
#     -H 'accept: application/json' \
#     -u "${HARBOR_USER}:${HARBOR_PASSWORD}" \
#     "https://harbor.test.slainte.at/api/v2.0/projects/${project}/repositories/${image}/artifacts/${tag}"
# Build and push the image to Harbor
${build} login ${HARBOR_LINK} -u ${HARBOR_USER} -p ${HARBOR_PASSWORD}
# --network=host is needed becaus of lxd-container networking issues
${build} build --network=host --no-cache --force-rm . -t ${HARBOR_LINK}/${project}/${image}:${tag} -f dockerfile
digest=$(${build} push ${HARBOR_LINK}/${project}/${image}:${tag} --digestfile=/dev/stdout | tail -n 1)

export COSIGN_PASSWORD="${HARBOR_MAINTAINER_PASSWORD}"
cosign sign --key ~/.cosign/cosign.key --allow-insecure-registry  ${HARBOR_LINK}/${project}/${image}@${digest}

# cat << EOF > ${build}_${project}_${image}_${tag}.sh
# #!/bin/bash
# ############################################################################################
# #
# # sign the image with cosign - This script only works on the node where Harbor is running, because it needs to access the Harbor service via the clusterIP.
# #
# ############################################################################################
# #shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
# #shopt -o -s xtrace #—Displays each command before it is executed.
# shopt -o -s nounset #-No Variables without definition
# # Get service information from Harbor
# HARBOR_LINK=\$(sudo microk8s kubectl get services -n harbor harbor -o jsonpath='{.spec.clusterIP}')
# build="${build}"
# tag="${tag}"
# project="${project}"
# image="${image}"
# digest="${digest}"
# # sign the image with cosign
# export COSIGN_PASSWORD="\${HARBOR_MAINTAINER_PASSWORD}"
# cosign login \${HARBOR_LINK} --username=\${HARBOR_MAINTAINER} --password=\${HARBOR_MAINTAINER_PASSWORD}
# cosign sign --key cosign.key --allow-insecure-registry  \${HARBOR_LINK}/\${project}/\${image}@\${digest}
# #
# EOF
#
cat << EOF > ${build}_${project}_${image}_${tag}.env
############################################################################################
#
# This env file contains necessary variables to be used for creating kubernetes yaml files for deployment of the image ${HARBOR_LINK}/${project}/${image}:${tag}
#
############################################################################################
export HARBOR_LINK="${HARBOR_LINK}"
export build="${build}"
export tag="${tag}"
export project="${project}"
export image="${image}"
export digest="${digest}"
EOF
#