#!/bin/bash
################################################################################
#
# Local test for httpbin sample
#
# See https://istio.io/latest/docs/tasks/traffic-management/ingress/secure-ingress/
################################################################################
#shopt -o -s errexit   #—Terminates  the shell script if a command returns an error code.
#shopt -o -s xtrace    #—Displays each command before it is executed.
#shopt -o -s nounset   #-No Variables without definition
set -euo pipefail
export host=${1:-${K8S_ENVIRONMENT}.http-echo-simple.slainte.at}
export INGRESS_NAME=istio-ingressgateway
export INGRESS_NS=istio-system

echo "Get Ingress Gateway details for accessing the application"
export INGRESS_HOST=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export INGRESS_PORT=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
export SECURE_INGRESS_PORT=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
export TCP_INGRESS_PORT=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.spec.ports[?(@.name=="tcp")].port}')
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
#
echo "accessing ${host} viaINGRESS_HOST=$INGRESS_HOST on SECURE_INGRESS_PORT=$SECURE_INGRESS_PORT"
curl -v -H${host} --resolve "${host}:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
  "https://${host}:$SECURE_INGRESS_PORT/"