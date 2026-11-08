#!/usr/bin/env bash
############################################################################################
#
# duplicity backup script
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
set -Eeuo pipefail
umask 077

# --------------------------------------------------
# Configuration
# --------------------------------------------------

SOURCE="/home"
DEST="sftp://duplicity@omv/duplicity_test"

SSH_DIR="${HOME}/.ssh"
SSH_KEY="/mnt/duplicity-ssh/id_ed25519"
SSH_PUB_KEY="/mnt/duplicity-ssh/id_ed25519.pub"
SSH_KNOWN_HOSTS="/mnt/duplicity-ssh/known_hosts"

CREDENTIAL_DIR="/mnt/duplicity-backup-credentials"
PASSWORD_FILE="${CREDENTIAL_DIR}/password"
GPG_PRIVATE_KEY="${CREDENTIAL_DIR}/gpg.private_key.asc"

TMP_DIR="/mnt/duplicity-pvc/tmp"

RETENTION="1M"

# --------------------------------------------------
# Logging
# --------------------------------------------------

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

error() {
    log "ERROR: $*"
    exit 1
}

# --------------------------------------------------
# SSH initialization
# --------------------------------------------------

init_ssh() {

    log "Initializing SSH configuration"

    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"

    [[ -f "$SSH_KEY" ]] || error "SSH private key missing"
    [[ -f "$SSH_KNOWN_HOSTS" ]] || error "Trusted known_hosts file missing"

    install -m 600 "$SSH_KEY" "$SSH_DIR/id_ed25519"
    install -m 644 "$SSH_PUB_KEY" "$SSH_DIR/id_ed25519.pub"
    install -m 600 "$SSH_KNOWN_HOSTS" "$SSH_DIR/known_hosts"

    cat > "$SSH_DIR/config" <<EOF
Host omv
    HostName omv.slainte.at
    User duplicity
    IdentityFile $SSH_DIR/id_ed25519
    IdentitiesOnly yes
    StrictHostKeyChecking yes
    UserKnownHostsFile $SSH_DIR/known_hosts
EOF

    chmod 600 "$SSH_DIR/config"

}

# --------------------------------------------------
# GPG initialization
# --------------------------------------------------

init_gpg() {

    log "Initializing GPG"

    [[ -f "$PASSWORD_FILE" ]] || error "Password file missing"
    [[ -f "$GPG_PRIVATE_KEY" ]] || error "GPG private key missing"

    export PASSPHRASE
    IFS= read -r PASSPHRASE < "$PASSWORD_FILE" || true

    [[ -n "$PASSPHRASE" ]] || error "Empty GPG passphrase"

    gpg --batch --import "$GPG_PRIVATE_KEY"

}

# --------------------------------------------------
# Duplicity initialization
# --------------------------------------------------

init_duplicity() {

    log "Initializing Duplicity"

    mkdir -p "$TMP_DIR"
    chmod 700 "$TMP_DIR"

    export TMPDIR="$TMP_DIR"

    # SFTP uses SSH public-key authentication.
    unset SSHPASS || true

    log "Duplicity version:"
    duplicity --version

}

# --------------------------------------------------
# Backup
# --------------------------------------------------

backup() {

    log "Starting backup"

    duplicity \
        --verbosity info \
        "$SOURCE" \
        "$DEST"

    log "Backup completed successfully"

}

# --------------------------------------------------
# Check
# --------------------------------------------------

check() {

    log "Checking backup collection"

    duplicity \
        collection-status \
        "$DEST"

    log "Verifying backup data"

    duplicity \
        verify \
        --compare-data \
        "$DEST" \
        "$SOURCE"

    log "Backup verification completed successfully"

}

# --------------------------------------------------
# Keep / Retention
# --------------------------------------------------

keep() {

    log "Removing backups older than ${RETENTION}"

    duplicity \
        remove-older-than "$RETENTION" \
        --force \
        "$DEST"

    log "Cleaning up unused backup files"

    duplicity \
        cleanup \
        --force \
        "$DEST"

    log "Retention completed successfully"

}

# --------------------------------------------------
# Main
# --------------------------------------------------

main() {

    ACTION="${1:-all}"

    log "Starting Duplicity job: ${ACTION}"

    init_ssh
    init_gpg
    init_duplicity

    case "$ACTION" in

        backup)
            backup
            ;;

        check)
            check
            ;;

        keep)
            keep
            ;;

        all)
            backup
            check
            keep
            ;;

        *)
            error "Usage: $0 {backup|check|keep|all}"
            ;;

    esac

    log "Duplicity job completed successfully"

}

main "$@"


exit


export PASSPHRASE=$(cat /mnt/duplicity-backup-credentials/password)
export BACKEND_PASSWORD=$(cat /mnt/duplicity-backup-credentials/password )
export RSYNC_PASSWORD=$(cat /mnt/duplicity-backup-credentials/password)
export SSHPASS=$(cat /mnt/duplicity-backup-credentials/password)

sshpass -e ssh -o StrictHostKeyChecking=no duplicity_test@omv
sshpass -e duplicity --verbosity info /home sftp://duplicity_test@omv.slainte.at/./duplicity_test
