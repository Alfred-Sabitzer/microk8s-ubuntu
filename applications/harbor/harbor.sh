#!/bin/bash
############################################################################################
#
# Install and configure Harbor on MicroK8s.
#
# https://github.com/goharbor/harbor
# https://goharbor.io/
# https://goharbor.io/docs/2.15.0/install-config/harbor-ha-helm/
#
############################################################################################
set -euo pipefail
#shopt -o -s xtrace #—Displays each command before it is executed.

trap 'rc=$?; if [ $rc -ne 0 ]; then echo "Script failed with exit $rc" >&2; fi; exit $rc' EXIT

usage() {
  cat <<EOF
Usage: $(basename "$0") [--help]

Install or refresh Harbor on MicroK8s.

Environment variables:
  K8S_ENVIRONMENT      Environment suffix used in the default hostname (default: test)
  NAMESPACE            Namespace for the Harbor resources (default: harbor)
  HARBOR_HOSTNAME      External Harbor hostname (default: harbor.${K8S_ENVIRONMENT}.slainte.at)
  HARBOR_STORAGE_CLASS Storage class used for Harbor persistent volumes (default: cephfs)
  WAIT_SECONDS         Helm wait timeout in seconds (default: 180)
  RETRY_ATTEMPTS       Number of retries for kubectl apply/delete operations (default: 5)
  RETRY_DELAY          Delay in seconds between retries (default: 5)
  MICROK8S_CMD         Optional override for the MicroK8s CLI prefix (for example: "sudo microk8s")
EOF
}

die() { echo "Error: $*" >&2; exit 1; }

retry() {
  local attempts="$1"
  shift
  local delay="$1"
  shift
  local attempt
  for attempt in $(seq 1 "$attempts"); do
    if "$@"; then
      return 0
    fi
    echo "Attempt ${attempt}/${attempts} failed. Retrying in ${delay}s..."
    sleep "$delay"
  done
  return 1
}

require_command() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: $cmd"
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

require_command envsubst
require_command find

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MICROK8S_CMD_VALUE="sudo microk8s"
read -r -a MICROK8S_CMD_ARRAY <<< "$MICROK8S_CMD_VALUE"

if [[ ${#MICROK8S_CMD_ARRAY[@]} -eq 0 ]]; then
  die "MICROK8S_CMD must not be empty"
fi

require_command "${MICROK8S_CMD_ARRAY[0]}"

KUBECTL_CMD="${MICROK8S_CMD_VALUE} kubectl"
HELM_CMD="${MICROK8S_CMD_VALUE} helm"

export NAMESPACE="${NAMESPACE:-harbor}"
export K8S_ENVIRONMENT="${K8S_ENVIRONMENT:-test}"
export HARBOR_HOSTNAME="${HARBOR_HOSTNAME:-https://harbor.${K8S_ENVIRONMENT}.slainte.at}"
export HARBOR_STORAGE_CLASS="${HARBOR_STORAGE_CLASS:-cephfs}"
export HARBOR_HELM_REPO_URL="${HARBOR_HELM_REPO_URL:-https://helm.goharbor.io}"
export HARBOR_HELM_RELEASE_NAME="${HARBOR_HELM_RELEASE_NAME:-harbor}"
WAIT_SECONDS="${WAIT_SECONDS:-180}"
RETRY_ATTEMPTS="${RETRY_ATTEMPTS:-5}"
RETRY_DELAY="${RETRY_DELAY:-5}"

delete_yaml_resources() {
  local file="$1"
  if ! retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" envsubst < "$file" | ${KUBECTL_CMD} delete --ignore-not-found=true -f -; then
    die "Failed to delete resources from $file"
  fi
}

apply_yaml_resources() {
  local file="$1"
  if ! retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" envsubst < "$file" | ${KUBECTL_CMD} apply -f -; then
    die "Failed to apply $file after $RETRY_ATTEMPTS attempts"
  fi
}

echo "Using namespace: $NAMESPACE"
echo "Using Harbor hostname: $HARBOR_HOSTNAME"
echo "Using storage class: $HARBOR_STORAGE_CLASS"

echo "Uninstalling any existing Harbor release..."
${HELM_CMD} uninstall "$HARBOR_HELM_RELEASE_NAME" --namespace "$NAMESPACE" --ignore-not-found=true || true

echo ""
echo "Finding YAML files in $SCRIPT_DIR..."
mapfile -t yamls < <(find "$SCRIPT_DIR" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort -r)

echo "Found ${#yamls[@]} YAML file(s)."
echo ""
echo "========== delete YAML resources =========="
for f in "${yamls[@]}"; do
  echo ""
  echo "Deleting: $f"
  delete_yaml_resources "$f"
done

mapfile -t yamls < <(find "$SCRIPT_DIR" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort)
echo "Found ${#yamls[@]} YAML file(s)."
echo ""
echo "========== apply YAML resources =========="
for f in "${yamls[@]}"; do
  echo ""
  echo "Applying: $f"
  apply_yaml_resources "$f"
done

echo "Adding Harbor Helm repository..."
if ! ${HELM_CMD} repo add harbor "$HARBOR_HELM_REPO_URL" >/dev/null 2>&1; then
  echo "Updating existing Harbor Helm repository..."
  ${HELM_CMD} repo update >/dev/null
fi

# ${HELM_CMD} fetch harbor/harbor --untar
#
# Extract password

dbpassword=$(${KUBECTL_CMD} get secrets -n $NAMESPACE postgres -o json | jq .data.password | sed 's/"//g' | base64 -d)

echo "Installing Harbor Helm chart... ${HELM_CMD} upgrade $HARBOR_HELM_RELEASE_NAME harbor/harbor "
# --debug

${HELM_CMD}  upgrade --install "$HARBOR_HELM_RELEASE_NAME" harbor/harbor \
  --create-namespace \
  --namespace "$NAMESPACE" \
  --wait \
  --set expose.type=clusterIP \
  --set expose.tls.enabled=false \
  --set externalURL="$HARBOR_HOSTNAME" \
  --set persistence.enabled="true" \
  --set persistence.resourcePolicy=keep \
  --set persistence.persistentVolumeClaim.registry.existingClaim="" \
  --set persistence.persistentVolumeClaim.registry.storageClass="$HARBOR_STORAGE_CLASS" \
  --set persistence.persistentVolumeClaim.registry.accessMode=ReadWriteMany \
  --set persistence.persistentVolumeClaim.jobservice.jobLog.existingClaim="" \
  --set persistence.persistentVolumeClaim.jobservice.jobLog.storageClass="$HARBOR_STORAGE_CLASS" \
  --set persistence.persistentVolumeClaim.jobservice.jobLog.accessMode="ReadWriteMany" \
  --set persistence.persistentVolumeClaim.database.existingClaim="" \
  --set persistence.persistentVolumeClaim.database.storageClass="$HARBOR_STORAGE_CLASS" \
  --set persistence.persistentVolumeClaim.database.accessMode="ReadWriteMany" \
  --set persistence.persistentVolumeClaim.redis.existingClaim="" \
  --set persistence.persistentVolumeClaim.redis.storageClass="$HARBOR_STORAGE_CLASS" \
  --set persistence.persistentVolumeClaim.redis.accessMode="ReadWriteMany" \
  --set persistence.persistentVolumeClaim.trivy.existingClaim="" \
  --set persistence.persistentVolumeClaim.trivy.storageClass="$HARBOR_STORAGE_CLASS" \
  --set persistence.persistentVolumeClaim.trivy.accessMode="ReadWriteMany" \
  --set database.internal.password="${dbpassword}" \
  --set existingSecretAdminPassword="secretadminpassword" \
  --set existingSecretAdminPasswordKey="password" \
  --set existingSecretSecretKey="secretadminpassword" \
  --set metrics.enabled="true" \
  --set metrics.serviceMonitor.enabled="false" \
  --set registry.existingSecret="registrysecret" \
  --set registry.existingSecretKey="password" \
  --set registry.credentials.existingSecret="registrycredentials"

# now label the services right after the helm install, so that the prometheus operator can pick them up
echo "Labeling Harbor services for Prometheus monitoring..."
${KUBECTL_CMD} label service -n "$NAMESPACE" "$HARBOR_HELM_RELEASE_NAME"-core metrics=enabled --overwrite
${KUBECTL_CMD} label service -n "$NAMESPACE" "$HARBOR_HELM_RELEASE_NAME"-jobservice metrics=enabled --overwrite
${KUBECTL_CMD} label service -n "$NAMESPACE" "$HARBOR_HELM_RELEASE_NAME"-registry metrics=enabled --overwrite
${KUBECTL_CMD} label service -n "$NAMESPACE" "$HARBOR_HELM_RELEASE_NAME"-exporter metrics=enabled --overwrite

echo "Installation done. You can access Harbor at: $HARBOR_HOSTNAME"
exit

####
My current assessment

The authentication files (auth.json, .docker/config.json, etc.) are not the problem. Those messages are expected during a first login.

The evidence strongly indicates that the failure occurs after successful authentication, during the authenticated /v2/ request. The next step is to compare the actual HTTP request Podman sends with the one your successful curl sends. That comparison should reveal the difference.



####

How to generate a proper client certificate

You should create a CSR:

openssl req \
    -new \
    -newkey rsa:2048 \
    -nodes \
    -keyout client.key \
    -out client.csr

Create an extension file:

basicConstraints = CA:FALSE
keyUsage = digitalSignature,keyEncipherment
extendedKeyUsage = clientAuth
subjectAltName = email:alfred@slainte.at

Then sign it:

openssl x509 \
    -req \
    -in client.csr \
    -CA ca.crt \
    -CAkey ca.key \
    -CAcreateserial \
    -days 365 \
    -extfile client.ext \
    -out client.crt

The resulting certificate should show:

Version: 3 (0x2)

X509v3 Key Usage:
    Digital Signature, Key Encipherment

X509v3 Extended Key Usage:
    TLS Web Client Authentication


####    


Dieser Fehler tritt auf, weil Podman nun zwar erfolgreich eine verschlüsselte TLS/mTLS-Verbindung mit Ihrem Istio-Ingress aufbaut, das Harbor-Backend dahinter (der Token-Service) jedoch eine ungültige oder relative URL zurückgibt. [1] 
Wenn Podman versucht, Benutzername und Passwort zu verifizieren, fragt es Harbor nach einem Authentifizierungs-Token. Harbor schickt in seiner Antwort (Header Www-Authenticate) die Adresse des Token-Servers mit. Wenn dort fälschlicherweise das Protokoll fehlt (z. B. nur harbor.test.slainte.at/... statt https://slainte.at...), bricht der Go-Client von Podman mit der Meldung unsupported protocol scheme "" ab. [1, 2, 3, 4] 
Das Problem liegt an der Istio-Konfiguration oder der Harbor app.conf, da Harbor nicht weiß, dass es hinter einem HTTPS-Proxy (Istio Gateway) läuft, und Links ohne https:// generiert. [5, 6] 
## 1. Sofortige Fehlerursache in Harbor beheben
Harbor muss explizit wissen, dass die externe URL mit https läuft. In der Regel müssen Sie in der harbor.yml (oder dem Harbor Helm Chart) folgende Parameter prüfen:

* 
* external_url: Muss zwingend mit https:// beginnen:

external_url: https://slainte.at

* 

## 2. Istio-Gateway Header prüfen
Wenn Istio den Request an Harbor weiterleitet, bricht die SSL/TLS-Verschlüsselung oft am Istio-Gateway ab (SSL Termination). Harbor denkt dann, der Request sei reines HTTP.
Stellen Sie sicher, dass Ihr Istio VirtualService oder Envoy-Filter den Header X-Forwarded-Proto: https mitsendet. Harbor wertet diesen aus, um die korrekten Token-URLs zu generieren. [5, 6] 
## 3. Gegencheck mit curl
Sie können überprüfen, was Harbor genau an Podman zurückliefert, indem Sie den mTLS-Aufruf im Terminal simulieren. Führen Sie diesen Befehl aus: [7] 

curl -v --cacert /etc/containers/certs.d/harbor.test.slainte.at/ca.crt \
     --cert /etc/containers/certs.d/harbor.test.slainte.at/client.cert \
     --key /etc/containers/certs.d/harbor.test.slainte.at/client.key \
     https://slainte.at

Worauf Sie in der Ausgabe achten müssen:
Suchen Sie in den Zeilen, die mit < beginnen, nach dem Header Www-Authenticate oder Location. Dort werden Sie sehen, dass Harbor eine URL ohne Protokoll mitsendet:

Www-Authenticate: Bearer realm="harbor.test.slainte.at/service/token",service="harbor-registry"

Sobald Sie Harbor/Istio so konfiguriert haben, dass dort realm="https://slainte.at..." steht, funktioniert auch der podman login fehlerfrei. [1] 
Wenn Sie möchten, teilen Sie mir die Ausgabe des curl-Befehls (speziell die < Www-Authenticate Zeile) oder Ihre Harbor-Konfigurations-Art (Helm Chart oder docker-compose) mit, damit ich Ihnen den exakten Konfigurations-Fix für die YAML-Datei geben kann.
