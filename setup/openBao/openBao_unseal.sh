#!/bin/bash
############################################################################################
#
# Unseal OpenBao on MicroK8s
#
# https://openbao.org/
# https://openbao.org/docs/platform/k8s/helm/
# https://www.linode.com/docs/guides/deploy-openbao-on-linode-kubernetes-engine/
#
############################################################################################
set -euo pipefail
# Unseal OpenBao Vault
date
echo "Unseal keys and initial root token are stored in the ConfigMap 'openbao-unseal-config' in the 'openbao' namespace."
mypod=$(kubectl get pods -l app.kubernetes.io/name=openbao -n openbao -o jsonpath='{.items[0].metadata.name}')
sealed=$(kubectl exec -i ${mypod} -n openbao -- bao status | grep -i Sealed) || true
if [[ -z "${sealed}" ]]; then
  echo "OpenBao Vault is not running or the pod is not available."
  exit 1
fi
sealed=${sealed#* }  # remove prefix ending in " "
sealed_status=$(echo -e "${sealed}" | tr -d '[:space:]')
if [[ "${sealed_status}" != "false" ]]; then
  echo "OpenBao Vault is still sealed. Unsealing is required. #${sealed_status}#"
  mymap=$(kubectl get configmaps -n openbao openbao-unseal-config -o yaml)
  echo "# Unsealing OpenBao Vault..." > /tmp/unseal_openbao.sh
  while IFS= read -r line; 
  do 
    #echo "${line}"; 
    key=${line#*:}   # remove prefix ending in ":"
    #echo "${key}"; 
    echo "kubectl exec -i ${mypod} -n openbao -- bao operator unseal "${key} >> /tmp/unseal_openbao.sh
  done < <(echo "${mymap}" | grep -i " Unseal Key ")
  chmod 755 /tmp/unseal_openbao.sh
  /tmp/unseal_openbao.sh
  echo "OpenBao Vault has been unsealed successfully."
  # Clean up temporary files
  rm -f /tmp/unseal_openbao.sh
else
  echo "OpenBao Vault is already unsealed."
  exit 0
fi