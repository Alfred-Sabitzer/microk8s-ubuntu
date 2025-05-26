#!/bin/bash
############################################################################################
#
# MicroK8S Adaption des Grafana Passwortes (Standard ist admin/admin)
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.

exit 0

k exec -i -t -n observability kube-prom-stack-grafana-6c48445779-9mwg2 -c grafana "--" sh -c "clear; (bash || ash || sh)"

Geht im Moment nicht, da der observability-Stack anders tickt;)


shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition
workdir=$(pwd)
# Herausfinden des Pods
pod=$(kubectl get pods -n monitoring | grep -i grafana)
pod=$(echo "${pod}" | awk '{print $1 }')
#echo "$pod"
#inisection=$(kubectl exec --stdin --tty -n monitoring "${pod}" -- /bin/bash ps -ef | grep -i grafana)
#echo "$inisection"
# Laden des Passwortes
secret=$(kubectl get secret -n monitoring grafana-frontend-api -o json | jq -c '. | {data}' )
#
apiurl=${secret#*"apiUrl\":\""}
apiurl=${apiurl%"\",\"password\""*}
apiurl=$(echo "${apiurl}" | base64 -d)
apiurl=${apiurl#*"https://"}
#
password=${secret#*"password\":\""}
password=${password%"\",\"username\""*}
password=$(echo "${password}" | base64 -d)
#
username=${secret#*"username\":\""}
username=${username%"\"}}"*}
username=$(echo "${username}" | base64 -d)
# Ändern des Passwortes (schreiben eines Bash-Skriptes und laden in den Pod, dann execute)
# https://grafana.com/docs/grafana/latest/cli/
#
cat <<EOF > "${workdir}"/tmp_set_password.sh
#!/bin/bash
#
# Setzen des Passwortes
#
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition

grafana-cli --homepath "/usr/share/grafana" admin reset-admin-password ${password}

EOF
chmod 755 "${workdir}"/tmp_set_password.sh
# Laden der Datei in den Pod
#kubectl cp ${workdir}/tmp_set_password.sh -n monitoring ${pod}:/
cat "${workdir}"/tmp_set_password.sh | kubectl exec -tt -n monitoring "${pod}" -- /bin/bash
rm -f "${workdir}"/tmp_set_password.sh
# Importieren der Reports
cd ./Grafana
./Import_all_Reports.sh
cd "${workdir}"
#
# Jetzt sind die Reports verfügbar
#