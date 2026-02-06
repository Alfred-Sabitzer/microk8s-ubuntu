#!/bin/bash
############################################################################################
#
# Test registry
# please consider https://microk8s.io/docs/registry-built-in
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
shopt -o -s nounset #-No Variables without definition

# Anzeige der Repository-Einträge
repositories=$(curl -k -s https://${K8S_REGISTRY}/v2/_catalog)
echo "Repositories: ${repositories}"
for repo in $(echo "${repositories}" | jq -r '.repositories[]'); do
  echo ${repo}
  tags=$(curl -k -s "https://${K8S_REGISTRY}/v2/${repo}/tags/list" | jq -r '.tags[]')
  for tag in ${tags}; do
    echo "____"${tag}
  done
done
#
