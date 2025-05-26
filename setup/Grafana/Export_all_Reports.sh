#!/bin/bash
############################################################################################
#
# MicroK8S Exportieren aller Grafana Dashboards
# https://gist.github.com/crisidev/bd52bdcc7f029be2f295
#
# Dazu muß händisch das Passwort im Grafana eingetragen werden, dass in monitoring/grafana-frontend-api im Keepassx registriert ist
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition
workdir=$(pwd)
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
#
# Iterate through dashboards using the current Connection
for dashboard_uid in $(curl -sS -L http://${username}:${password}@localhost:3000/api/search\?query\=\& | jq -r '.[] | select( .type | contains("dash-db")) | .uid'); do
    url="http://${username}:${password}@localhost:3000/api/dashboards/uid/$dashboard_uid"
    dashboard_json=$(curl -sS $url)

    dashboard_title=$(echo ${dashboard_json} | jq -r '.dashboard | .title' | sed -r 's/[ \/]+/_/g' )
    dashboard_version=$(echo ${dashboard_json} | jq -r '.dashboard | .version')
    folder_title="$(echo ${dashboard_json} | jq -r '.meta | .folderTitle')"
    echo "./${folder_title}/${dashboard_title}_v${dashboard_version}.json"
    mkdir -p "./${folder_title}"
    echo "${dashboard_json}" > ./${folder_title}/${dashboard_title}_v${dashboard_version}.json
done
#
kill ${pid}
#
# Jetzt sind alle Dashboards exportiert
#
