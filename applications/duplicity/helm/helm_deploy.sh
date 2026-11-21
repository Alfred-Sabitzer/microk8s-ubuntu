#!/bin/bash
############################################################################################
#
# build and deploy via Helm
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
shopt -o -s nounset #-No Variables without definition
set -Eeuo pipefail
trap 'rc=$?; error "Script failed at line ${LINENO}, exit code ${rc}, command: ${BASH_COMMAND}"; exit "$rc"' ERR

KUBECTL_CMD="sudo microk8s.kubectl"
HELM_CMD="sudo microk8s.helm"
export SOURCING_ENVIRONMENT="${2:-duplicity.env}"


# --------------------------------------------------
# Logging
# --------------------------------------------------

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

error() {
    log "❌ ERROR: $*"
    exit 1
}

die() { printf '❌  Error: %s\n' "$1" >&2; exit 1; }

retry() {
    local max_attempts=$1; shift
    local delay=$1; shift
    local attempt=1

    # echo "Executing command: $@ (max_attempts=$max_attempts, delay=${delay}s)"
    until "$@"; do
        if (( attempt >= max_attempts )); then
            echo "❌ Error: Command failed after $attempt attempts." >&2
            return 1
        fi
        
        local current_delay=$(( attempt * delay ))
        echo "⚠️ Command failed. Retrying $attempt of $max_attempts. Waiting ${current_delay}s..." >&2
        sleep "${current_delay}s"  # Exponential backoff
        
        ((attempt++))
    done
}

# --------------------------------------------------
# Check
# --------------------------------------------------

check() {

    log "Checking helm-installation ${RELEASE_NAME} for namespace ${TARGET_NAMESPACE}"

    ${HELM_CMD} list -n ${TARGET_NAMESPACE}

    ${HELM_CMD} status -n ${TARGET_NAMESPACE} ${RELEASE_NAME} --show-desc --show-resources

    log "Checks completed successfully"

}

# --------------------------------------------------
# Check all
# --------------------------------------------------

check-all() {

    log "Checking all of helm-installation ${RELEASE_NAME} for namespace ${TARGET_NAMESPACE}"

    ${HELM_CMD} list -n ${TARGET_NAMESPACE}

    ${HELM_CMD} get all -n ${TARGET_NAMESPACE} ${RELEASE_NAME}

    ${HELM_CMD} get values -n ${TARGET_NAMESPACE} ${RELEASE_NAME}

    log "Checks completed successfully"

}


# --------------------------------------------------
# Delete
# --------------------------------------------------

delete() {

    log "Delete Installation ${RELEASE_NAME} for namespace ${TARGET_NAMESPACE}"

    ${HELM_CMD} uninstall --ignore-not-found -n ${TARGET_NAMESPACE} ${RELEASE_NAME}

    log "Deletion completed successfully"

}

# --------------------------------------------------
# Install
# --------------------------------------------------

install() {

    log "Installing ${RELEASE_NAME} for namespace ${TARGET_NAMESPACE}"

    ${HELM_CMD} upgrade --install ${RELEASE_NAME} ./ \
    --namespace "${TARGET_NAMESPACE}" \
    --create-namespace \
    --set namespace="${TARGET_NAMESPACE}" \
    --set image.registry="${HARBOR_LINK}" \
    --set image.tag="${tag}" \
    --set image.project="${project}" \
    --set image.repository="${image}" \
    --set image.digest="${digest}" \
    --set buildInfo.tool="${build}" \
    --set backup.bucket="${SOURCE_BUCKET_NAME}" \

    log "Installation completed successfully"

}

# --------------------------------------------------
# Main
# --------------------------------------------------

main() {

    log "Sourcing Environment ${SOURCING_ENVIRONMENT}"
    source ${SOURCING_ENVIRONMENT}

    ACTION="${1:-check}"

    log "Starting Duplicity job: ${ACTION}"


    case "$ACTION" in

        install)
            install
            ;;

        delete)
            delete
            ;;

        redeploy)
            redeploy
            ;;

        check)
            check
            ;;

        check-all)
            check-all
            ;;

        *)
            error "⚠️ Usage: $0 {install|delete|redeploy|check|check-all} <FQFN to environment-file>"
            ;;

    esac

    log "👍 Helm ${ACTION} completed successfully"
}

main "$@"

exit