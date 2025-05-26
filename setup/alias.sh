#!/bin/bash
############################################################################################
#
# Einrichten der Aliase
# Please consider https://gist.github.com/demiters/c322d99db658e37ba30c8f13ba8b434b
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition
#
# Remove aliase
#
sed -i '/kubectl/I d' ~/.bashrc
sed -i '/helm/I d' ~/.bashrc
#
# Define aliase
#
cat <<EOF >> ~/.bashrc
# start kubectl and helm settings
source <(kubectl completion bash)
alias kubectl="microk8s kubectl"
alias k=kubectl
complete -F __start_kubectl k
# helm settings
alias helm="microk8s helm3"
alias h=helm
# end kubectl and helm settings
EOF
#
sudo kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl
#
