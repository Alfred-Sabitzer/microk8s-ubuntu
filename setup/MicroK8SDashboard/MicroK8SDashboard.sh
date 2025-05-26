#!/bin/bash
############################################################################################
#
# MicroK8S Einrichten des Dashboards, Prometheus und Metrics Services
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition
indir=$(dirname "$0")
# Disablen
microk8s disable dashboard-ingress                              # Ingress definition for Kubernetes dashboard
microk8s disable dashboard                                      # The Kubernetes dashboard
kubectl delete -f ${indir}/dashboard-service-account.yaml       # Token für den Serviceaccount
microk8s status --wait-ready
# Enable
microk8s enable dashboard                                       # The Kubernetes dashboard
microk8s enable dashboard-ingress                               # Ingress definition for Kubernetes dashboard
kubectl apply -f ${indir}/dashboard-service-account.yaml         # Servie Account für den Cluster-Admin
microk8s status --wait-ready
# For MicroK8s 1.24 or newer
microk8s kubectl create token cluster-admin -n kube-system --duration=8760h
# Dieses Token gehört dann in die .kube/config

# Anzeigen der Tokens
#kubectl -n kube-system get secrets microk8s-dashboard-token -o go-template="{{.data.token | base64decode}}"
# kubectl -n kube-system get secret $(kubectl -n kube-system get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}"
# kubectl -n kube-system describe secret $(microk8s kubectl -n kube-system get secret | grep default-token | cut -d " " -f1)
# kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print \$1}')
#
# Jetzt sind alle Standard-Services verfügbar
#
# kubernetes-dashboard.127.0.0.1.nip.io in die /etc/hosts Datei eintragen, und man kann über den Ingress auf das Dashboard zugreifen
#