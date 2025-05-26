#!/bin/bash
############################################################################################
#
# MicroK8S Importieren aller Grafana Dashboards
#
# https://grafana.com/docs/grafana/latest/http_api/dashboard/#create-update-dashboard
# https://github.com/monitoringartist/grafana-utils
#
# Dazu muß händisch das Passwort im Grafana eingetragen werden, dass in monitoring/grafana-frontend-api im Keepassx registriert ist
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition
#
secret=$(kubectl get secret -n monitoring grafana-frontend-api -o json | jq -c '. | {data}' )
#
apiurl=${secret#*"apiUrl\":\""}
apiurl=${apiurl%"\",\"password\""*}
apiurl=$(echo ${apiurl} | base64 -d)
apiurl=${apiurl#*"https://"}
#
password=${secret#*"password\":\""}
password=${password%"\",\"username\""*}
password=$(echo ${password} | base64 -d)
#
username=${secret#*"username\":\""}
username=${username%"\"}}"*}
username=$(echo ${username} | base64 -d)
#
cmd="kubectl -n monitoring port-forward service/grafana 3000:3000"
${cmd} &
pid=$!
sleep 3s
FILES="./General/*.json
"
#
for filename in $FILES ; do
  if [ -f "${filename}" ]
  then
    echo ${filename}
    cat ${filename} | jq '. * {overwrite: true, dashboard: {id: null}}' | curl -L -X POST -H "Content-Type: application/json" http://${username}:${password}@localhost:3000/api/dashboards/db -d @-
  fi
done
#
kill ${pid}
#
# Jetzt sind alle Dashboards verfügbar
#