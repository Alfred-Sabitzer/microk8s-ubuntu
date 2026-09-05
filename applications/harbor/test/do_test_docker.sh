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
build="docker"
tag=$(date +"%Y%m%d")
project="test"
image="dummy"
HARBOR_LINK="harbor.test.slainte.at"
# Build and push the image to Harbor
${build} login ${HARBOR_LINK} -u ${HARBOR_USER} -p ${HARBOR_PASSWORD}
# --network=host is needed becaus of lxd-container networking issues
${build} build --network=host --no-cache --force-rm . -t ${HARBOR_LINK}/${project}/${image}:${tag} -f dockerfile
result=$(${build} push ${HARBOR_LINK}/${project}/${image}:${tag})
# The push refers to repository [harbor.test.slainte.at/test/dummy] 44136fa355b3: Waiting c495cb657027: Waiting 55afa1ecc21d: Waiting b7a6f056e373: Waiting c495cb657027: Waiting 55afa1ecc21d: Waiting b7a6f056e373: Waiting 44136fa355b3: Waiting ef7ed7791152: Waiting b7a6f056e373: Waiting 44136fa355b3: Already exists c495cb657027: Waiting 55afa1ecc21d: Layer already exists 965cb6577f0b: Waiting 965cb6577f0b: Layer already exists ef7ed7791152: Layer already exists 6aa40f1e7ada: Waiting 6aa40f1e7ada: Layer already exists b7a6f056e373: Pushed c495cb657027: Pushed 20260831: digest: sha256:3e5b623180894602ae35231652797325b897958e2f266024f2ec6f4a68a44c02 size: 856

digest=${result#*digest: }  # remove prefix
digest=${digest% size:*}    # remove suffix

cat << EOF > ${build}_${project}_${image}_${tag}.sh
#!/bin/bash
############################################################################################
#
# sign the image with cosign - This script only works on the node where Harbor is running, because it needs to access the Harbor service via the clusterIP.
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
shopt -o -s nounset #-No Variables without definition
# Get service information from Harbor
export HARBOR_LINK=\$(sudo microk8s kubectl get services -n harbor harbor -o jsonpath='{.spec.clusterIP}')
build="${build}"
tag="${tag}"
project="${project}"
image="${image}"
digest="${digest}"
# sign the image with cosign
export COSIGN_USER=\$(sudo microk8s kubectl get secrets -n \${project} harbor-cosign -o jsonpath='{.data.username}' | base64 -d)
export COSIGN_PASSWORD=\$(sudo microk8s kubectl get secrets -n \${project} harbor-cosign -o jsonpath='{.data.password}' | base64 -d)
export COSIGN_PRIVATE_KEY=\$(sudo microk8s kubectl get secrets -n \${project} harbor-cosign -o jsonpath='{.data.cosign\.key}' | base64 -d)
export COSIGN_PUBLIC_KEY=\$(sudo microk8s kubectl get secrets -n \${project} harbor-cosign -o jsonpath='{.data.cosign\.pub}' | base64 -d)
#
export DOCKER_CONFIG=\$(mktemp -d)
cosign login \${HARBOR_LINK} --username=\${COSIGN_USER} --password=\${COSIGN_PASSWORD}

curl -v -u "${COSIGN_USER}:${COSIGN_PASSWORD}" "http://${HARBOR_LINK}/v2/${project}/${image}/blobs/uploads/" -X POST


cosign sign --key <(echo "\${COSIGN_PRIVATE_KEY}") --allow-insecure-registry  \${HARBOR_LINK}/\${project}/\${image}@\${digest}
# Verifying with a public key variable
cosign verify --key <(echo "\${COSIGN_PUBLIC_KEY}") --allow-insecure-registry  \${HARBOR_LINK}/\${project}/\${image}@\${digest}
rm -rf "\${DOCKER_CONFIG}"
unset COSIGN_USER
unset COSIGN_PASSWORD
unset COSIGN_PRIVATE_KEY
unset COSIGN_PUBLIC_KEY
#
EOF
chmod 755 ${build}_${project}_${image}_${tag}.sh
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