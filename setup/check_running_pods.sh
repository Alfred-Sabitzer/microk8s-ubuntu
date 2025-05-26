#!/bin/bash
############################################################################################
#
# Überprüfung ob alle Pods bereit sind
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition
sleep 30s
pods=$(kubectl get pods --all-namespaces | grep -v Running | grep -v NAMESPACE | grep -v Terminating | grep -v Completed )
while [[ ! "${pods} " == " " ]]
do
  date
  echo "${pods}"
  sleep 1m
  pods=$(kubectl get pods --all-namespaces | grep -v Running | grep -v NAMESPACE | grep -v Terminating | grep -v Completed )
done
