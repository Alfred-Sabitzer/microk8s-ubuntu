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
trap 'rc=$?; log "ERROR: Script failed at line ${LINENO}, exit code ${rc}, command: ${BASH_COMMAND}"; exit "$rc"' ERR

KUBECTL_CMD="kubectl"
HELM_CMD="helm"



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

    log "Checking helm-installation for namespace ${namespace}"

    ${helm} list -n ${namespace}

    ${helm} status ${RELEASE_NAME}

    ${helm} get all ${RELEASE_NAME}

    ${helm} get values ${RELEASE_NAME}

    log "Checks completed successfully"

}

# --------------------------------------------------
# Main
# --------------------------------------------------

main() {

    log "Sourcing Environment $2"
    source $2

    ACTION="${2:-check}"

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

        *)
            error "⚠️ Usage: $0 {install|delete|redeploy|check} <FQFN to environment-file>"
            ;;

    esac

    log "👍 Helm-Install completed successfully"

}

main "$@"

exit