#!/bin/bash
############################################################################################
#
# Einrichten der Aliase
# Please consider https://gist.github.com/demiters/c322d99db658e37ba30c8f13ba8b434b
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
shopt -o -s nounset #-No Variables without definition
#
# Define aliase
#
cat <<EOF > ~/.bash_aliases
# this is because of busybox see https://superuser.com/questions/1713520/why-does-busybox-ping-expect-root
alias ping="sudo ping"
# start kubectl and helm settings
alias microk8s="sudo microk8s"
alias kubectl="sudo sudo microk8s kubectl"
alias k="sudo sudo microk8s kubectl"
# helm settings
alias helm="sudo sudo microk8s helm3"
source <(kubectl completion bash)
complete -F __start_kubectl k
# end kubectl and helm settings
# Environment specific settings
if [ "$(hostname | cut -d'-' -f2)" = "k8stest" ]; then
    K8S_ENVIRONMENT="test"
    K8S_LETSENCRYPT="k8s-intermediate-issuer"
else
    K8S_ENVIRONMENT="k8s"
    K8S_LETSENCRYPT="letsencrypt"
fi
export K8S_ENVIRONMENT
export K8S_LETSENCRYPT
export K8S_REGISTRY="registry.${K8S_ENVIRONMENT}.slainte.at"
export K8S_HARBOR_REGISTRY="harbor.${K8S_ENVIRONMENT}.slainte.at"
# set default editor for kubectl to nano
export KUBE_EDITOR=nano
# Connect Kiali with Grafana
export KIALI_GRAFANA_TOKEN=$(echo -n "Please get the right token from your grafana installation" | base64 )
# OpenBao specific settings
if [ "x${K8S_OPENBAO_USER_PIN}" = "x" ]; then   
    K8S_OPENBAO_USER_PIN=$(head -c 32 /dev/urandom | base64)
fi
if [ "x${K8S_OPENBAO_SO_PIN}" = "x" ]; then   
    K8S_OPENBAO_SO_PIN=$(head -c 32 /dev/urandom | base64)
fi
export K8S_OPENBAO_USER_PIN
export K8S_OPENBAO_SO_PIN
if ! [ -f /etc/profile.d/openbao_pins.sh ]; then
cat <<- EOF2 | sudo tee /etc/profile.d/openbao_pins.sh
# OpenBao PINs
# Store these PINs securely as they are required to access OpenBao services.
#
export K8S_OPENBAO_USER_PIN=${K8S_OPENBAO_USER_PIN}
export K8S_OPENBAO_SO_PIN=${K8S_OPENBAO_SO_PIN}
EOF2
fi
#
OPENBAO_ROOT_TOKEN="Please define the root token for OpenBao here"
export OPENBAO_ROOT_TOKEN
#
EOF
#
sudo kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl
#
