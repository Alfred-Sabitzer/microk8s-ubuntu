#!/bin/bash
################################################################################
#
# Create client certificates
#
# https://kubernetes.io/docs/tasks/tls/certificate-issue-client-csr/
#
################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace     #—Displays each command before it is executed.
#shopt -o -s nounset    #-No Variables without definition
set -euo pipefail
trap 'rc=$?; if [ $rc -ne 0 ]; then echo "Script failed with exit $rc" >&2; fi; exit $rc' EXIT

usage() {
  cat <<EOF >&2
Usage: $0 -c certificate-name -u client-name -p password [-e client-email]

  -n namespace          Kubernetes namespace (default: default)
  -c certificate-name   Certificate name
  -u client-name        Output prefix / client name for created files
  -p password           Password for the generated PKCS#12 file
  -e client-email       Client email (optional, recorded in output)
  -h                    Show this help
EOF
  exit 1
}

# Parse args
namespace="default"
certificate_name="client-certificate"
client_name=""
client_email=""
password=""

while getopts ":n:c:u:e:p:h" opt; do
  case $opt in
    n) namespace="$OPTARG" ;;
    c) certificate_name="$OPTARG" ;;
    u) client_name="$OPTARG" ;;
    e) client_email="$OPTARG" ;;
    p) password="$OPTARG" ;;
    h) usage ;;
    :) echo "Option -$OPTARG requires an argument." >&2; usage ;;
    \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
  esac
done

if [ -z "${client_email}" ] || [ -z "${client_name}" ] || [ -z "${password}" ] || [ -z "${namespace}" ] || [ -z "${certificate_name}" ]; then
  echo "Missing required parameter(s)." >&2
  usage
fi

echo "Creating client certificate ${client_email} for client name: ${client_name} with ${client_email} based on certificate ${certificate_name} in namespace ${namespace} ... "
kubectl get secret "${certificate_name}" -n "${namespace}" -ogo-template='{{index .data "tls.key" }}' | base64 -d > ${certificate_name}.key
kubectl get secret "${certificate_name}" -n "${namespace}" -ogo-template='{{index .data "tls.crt" }}' | base64 -d > ${certificate_name}.crt
kubectl get secret "${certificate_name}" -n "${namespace}" -ogo-template='{{index .data "ca.crt" }}' | base64 -d > ${certificate_name}_ca.crt

# Generate a client certificate and private key:
#openssl genrsa -out ${client_email}.key 3072
openssl req -newkey rsa:2048 -nodes -keyout ${client_email}.key -out ${client_email}.csr -subj "/CN=${client_name}/O=frontend-users/emailAddress=${client_email}"

---- oooooooh ---- doch k8s ----

openssl x509 -req -sha256 -days 365 -CA ${certificate_name}_ca.crt -CAkey ${certificate_name}.key -set_serial 1 -in ${client_email}.csr -out ${client_email}.crt

# openssl req -out example_certs1/client.example.com.csr -newkey rsa:2048 -nodes -keyout example_certs1/client.example.com.key -subj "/CN=client.example.com/O=client organization"
# openssl x509 -req -sha256 -days 365 -CA example_certs1/example.com.crt -CAkey example_certs1/example.com.key -set_serial 1 -in example_certs1/client.example.com.csr -out example_certs1/client.example.com.crt


# Create a PKCS#12 keystore for the client certificate and key using provided password
####openssl pkcs12 -export -out ${client_email}.p12 -inkey ${client_email}.key -in ${client_email}.crt -name "${client_email}" -passout pass:"${password}"
# Convert PKCS#12 to PEM format (if needed)
###openssl pkcs12 -in ${client_email}.p12 -out ${client_email}.pem -nodes -passin pass:"${password}"

# Clean up temporary files
#rm ${client_email}.csr ${client_email}.key ${client_email}.crt

echo "${client_email}.p12 and ${client_email}.pem have been created successfully."
echo "You can use this PKCS#12 file to configure your HTTP client for mutual TLS authentication."

cat <<EOF > ${client_email}.sh
#!/bin/bash
################################################################################
#
# test client certificates
#
# https://kubernetes.io/docs/tasks/tls/certificate-issue-client-csr/
#
################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace     #—Displays each command before it is executed.
#shopt -o -s nounset    #-No Variables without definition
set -euo pipefail

# Test with curl:
host=\${1:-httpbin.example.com}
echo "Get Ingress Gateway details for accessing the application"

export INGRESS_NAME=istio-ingressgateway
export INGRESS_NS=istio-system

export INGRESS_HOST=\$(kubectl -n "\$INGRESS_NS" get service "\$INGRESS_NAME" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export INGRESS_PORT=\$(kubectl -n "\$INGRESS_NS" get service "\$INGRESS_NAME" -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
export SECURE_INGRESS_PORT=\$(kubectl -n "\$INGRESS_NS" get service "\$INGRESS_NAME" -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
export TCP_INGRESS_PORT=\$(kubectl -n "\$INGRESS_NS" get service "\$INGRESS_NAME" -o jsonpath='{.spec.ports[?(@.name=="tcp")].port}')
export GATEWAY_URL=\$INGRESS_HOST:\$INGRESS_PORT

echo "accessing \${host} INGRESS_HOST=\$INGRESS_HOST on SECURE_INGRESS_PORT=\$SECURE_INGRESS_PORT"
curl -v -HHost:\${host} --resolve "\${host}:\$SECURE_INGRESS_PORT:\$INGRESS_HOST" \
  --cacert ${certificate_name}_ca.crt --cert ${client_email}.crt --key ${client_email}.key \
  "https://\${host}:\$SECURE_INGRESS_PORT/status/418"
EOF
chmod +x ${client_email}.sh

# kubectl create -n istio-system secret generic httpbin-credential \
#   --from-file=tls.key=example_certs1/httpbin.example.com.key \
#   --from-file=tls.crt=example_certs1/httpbin.example.com.crt \
#   --from-file=ca.crt=example_certs1/example.com.crt

# openssl req -out example_certs1/client.example.com.csr -newkey rsa:2048 -nodes -keyout example_certs1/client.example.com.key -subj "/CN=client.example.com/O=client organization"
# openssl x509 -req -sha256 -days 365 -CA example_certs1/example.com.crt -CAkey example_certs1/example.com.key -set_serial 1 -in example_certs1/client.example.com.csr -out example_certs1/client.example.com.crt
# curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
#   --cacert example_certs1/example.com.crt --cert example_certs1/client.example.com.crt --key example_certs1/client.example.com.key \
#   "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
