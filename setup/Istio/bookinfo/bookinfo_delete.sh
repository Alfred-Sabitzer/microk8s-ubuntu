#!/bin/bash
################################################################################
#
# Delete Bookinfo sample application
#
# See https://istio.io/latest/docs/examples/bookinfo/
################################################################################
shopt -o -s errexit   #—Terminates  the shell script if a command returns an error code.
#shopt -o -s xtrace    #—Displays each command before it is executed.
shopt -o -s nounset   #-No Variables without definition
set -euo pipefail

export NAMESPACE="demo-istio"
export istio_dir="/opt/istio-installation/istio-1.28.1"

# Clean up any previous Bookinfo installation
echo "Cleaning up any previous Bookinfo installation in namespace '${NAMESPACE}'..."

chmod +x ${istio_dir}/samples/bookinfo/platform/kube/cleanup.sh
${istio_dir}/samples/bookinfo/platform/kube/cleanup.sh || true

