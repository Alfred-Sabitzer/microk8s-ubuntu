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
alias kubectl="microk8s kubectl"
alias k=kubectl
# helm settings
alias helm="microk8s helm3"
alias h=helm
source <(kubectl completion bash)
complete -F __start_kubectl k
# end kubectl and helm settings
# Environment specific settings
if [ "$(hostname | cut -d'-' -f2)" = "k8stest" ]; then
    K8S_ENVIRONMENT="test"
    K8S_LETSENCRYPT="k8s-issuer"
else
    K8S_ENVIRONMENT="k8s"
    K8S_LETSENCRYPT="letsencrypt"
fi
export K8S_ENVIRONMENT
export KUBE_EDITOR=nano
EOF
#
sudo kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl
#
