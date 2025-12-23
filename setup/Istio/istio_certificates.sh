#!/bin/bash
################################################################################
#
# Extract certificates into files
#
################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace     #—Displays each command before it is executed.
#shopt -o -s nounset    #-No Variables without definition
set -euo pipefail
trap 'rc=$?; if [ $rc -ne 0 ]; then echo "Script failed with exit $rc" >&2; fi; exit $rc' EXIT

get_secret() {
  local secret_name="$1"
  local namespace="$2"
  local key="$3"

  local b64_value
  b64_value=$(microk8s kubectl get secret "$secret_name" -n "$namespace" -ogo-template='{{index .data "'"$key"'" }}')

  if [ -z "$b64_value" ]; then
    echo "Error: Key '$key' not found in secret '$secret_name' in namespace '$namespace'."
    exit 1
  fi

  local decoded_value
  decoded_value=$(echo "$b64_value" | base64 -d)

  echo "$decoded_value" > ${secret_name}_${key}
}

# Extract Istio TLS certificates
secret_name="wildcard-slainte-at-mtls-credential"
namespace="istio-gateways"
issuername=$(microk8s kubectl get secret "$secret_name" -n "$namespace" -ogo-template='{{index .metadata "annotations" "cert-manager.io/issuer-name"}}')
certificatename=$(microk8s kubectl get secret "$secret_name" -n "$namespace" -ogo-template='{{index .metadata "annotations" "cert-manager.io/certificate-name"}}')

get_secret "${secret_name}" "${namespace}" "ca.crt"
get_secret "${secret_name}" "${namespace}" "tls.crt"
get_secret "${secret_name}" "${namespace}" "tls.key"
openssl pkcs12 -export -name ${certificatename} -caname ${issuername} -out ${certificatename}.p12 -inkey ${secret_name}_tls.key -in ${secret_name}_tls.crt -certfile ${secret_name}_ca.crt -passout pass:${certificatename}

# Extract Istio Client certificates
secret_name="client-lxd-slainte-at-mtls-credential"
namespace="istio-gateways"
issuername=$(microk8s kubectl get secret "$secret_name" -n "$namespace" -ogo-template='{{index .metadata "annotations" "cert-manager.io/issuer-name"}}')
certificatename=$(microk8s kubectl get secret "$secret_name" -n "$namespace" -ogo-template='{{index .metadata "annotations" "cert-manager.io/certificate-name"}}')

get_secret "${secret_name}" "${namespace}" "ca.crt"
get_secret "${secret_name}" "${namespace}" "tls.crt"
get_secret "${secret_name}" "${namespace}" "tls.key"
openssl pkcs12 -export -name ${certificatename} -caname ${issuername} -out ${certificatename}.p12 -inkey ${secret_name}_tls.key -in ${secret_name}_tls.crt -certfile ${secret_name}_ca.crt -passout pass:${certificatename}

echo "All certificates have been extracted successfully."

