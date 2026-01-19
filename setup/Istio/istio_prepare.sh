#!/bin/bash
################################################################################
#
# Prepare environment for Istio installation on MicroK8s.
#
#
# Prerequisites:
#   - sudo microk8s installed and running
#   - User in sudo microk8s group or run with sudo
#
################################################################################
set -euo pipefail
trap 'rc=$?; if [ $rc -ne 0 ]; then echo "Script failed with exit $rc" >&2; fi; exit $rc' EXIT

# remove ingress if exists
sudo microk8s disable ingress || true

# remove ingresses if exists
IFS=" "
while read NAMESPACE NAME CLASS HOSTS ADDRESS PORTS AGE
do
  echo "${NAME}"
  sudo microk8s kubectl delete ingresses.networking.k8s.io -n ${NAMESPACE} ${NAME}
done < <( sudo microk8s kubectl get ingresses.networking.k8s.io --all-namespaces | grep -v NAME )

exit 0