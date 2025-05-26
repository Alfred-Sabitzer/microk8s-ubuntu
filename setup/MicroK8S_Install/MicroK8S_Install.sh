#!/bin/bash
############################################################################################
#
# Install microk8s
# Please consider https://ubuntu.com/tutorials/install-a-local-kubernetes-with-microk8s#1-overview
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition

sudo snap install microk8s --classic --channel=latest/stable # I want to always be on the latest stable Kubernetes.
rc=$?
echo "Return-code: ${rc}"

while  [ ${rc} -gt 0 ]
do
  sleep 30s
  sudo "${MyVersion}"
  rc=$?
  echo "Return code: ${rc}"
done

sudo snap info microk8s | grep -i tracking
sudo snap unalias kubectl
sudo snap alias microk8s.kubectl kubectl

sudo ./MicroK8S_Start.sh
sudo microk8s inspect | sudo tee microk8s_inspect.log
#
# MicroK8s is installed now and waiting for you
#
