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
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail

# Unseal OpenBao Vault
echo "Unseal keys and initial root token are stored in the ConfigMap 'openbao-unseal-config' in the 'openbao' namespace."
echo "# Unsealing OpenBao Vault..." > /tmp/unseal_openbao.sh
mymap=$(microk8s kubectl get configmaps -n openbao openbao-unseal-config -o yaml)
while IFS= read -r line; 
do 
  #echo "${line}"; 
  key=${line#*:}   # remove prefix ending in "_"
  #echo "${key}"; 
  echo "microk8s kubectl exec -i ${mypod} -n openbao -- bao operator unseal "${key} >> /tmp/unseal_openbao.sh
done < <(echo "${mymap}" | grep -i " Unseal Key ")
chmod 755 /tmp/unseal_openbao.sh
/tmp/unseal_openbao.sh
echo "OpenBao Vault has been unsealed successfully."

# Clean up temporary files
rm -f /tmp/unseal_openbao.sh
