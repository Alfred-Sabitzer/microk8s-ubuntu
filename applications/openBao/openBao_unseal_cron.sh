#!/bin/bash
############################################################################################
#
# create a k8s-cron-job to unseal OpenBao Vault on MicroK8s automatically
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
indir="$(dirname "$0")"

croncmd="${indir}/openBao_unseal.sh > ~/openBao_unseal.log 2>&1 # unseal OpenBao Vault on MicroK8s. Only install on one node of the cluster"
cronjob="*/5 * * * * $croncmd"
( crontab -l | grep -v -F "$croncmd" ; echo "$cronjob" ) | crontab -

echo "Cronjob updated to run every 2 minutes: $croncmd"

