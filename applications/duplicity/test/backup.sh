#!/usr/bin/env bash
############################################################################################
#
# duplicity backup script
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
set -Eeuo pipefail
# • Dateien: 0666 minus 0022 = 0644 (rw-r--r--)
# • Ordner: 0777 minus 0022 = 0755 (rwxr-xr-x)
# umask 022

# --------------------------------------------------
# Configuration
# --------------------------------------------------

VERBOSITY="info"
#VERBOSITY="debug"

SOURCE="/mnt/source"
SSH_DIR="${HOME}/.ssh"
SSH_KEY="/mnt/duplicity-ssh/id_ed25519"
SSH_PUB_KEY="/mnt/duplicity-ssh/id_ed25519.pub"
SSH_KNOWN_HOSTS="/mnt/duplicity-ssh/known_hosts"

CREDENTIAL_DIR="/mnt/duplicity-backup-credentials"
PASSWORD_FILE="${CREDENTIAL_DIR}/password"
GPG_PRIVATE_KEY="${CREDENTIAL_DIR}/gpg.private_key.asc"
export FTPURL=$(cat ${CREDENTIAL_DIR}/url)
export FTPUSERNAME=$(cat ${CREDENTIAL_DIR}/username)
export SSHPASS=$(cat ${PASSWORD_FILE})
export PASSPHRASE=$(cat ${PASSWORD_FILE})
export BACKEND_PASSWORD=$(cat ${PASSWORD_FILE})
export RSYNC_PASSWORD=$(cat ${PASSWORD_FILE})
export FTP_PASSWORD="$(cat ${PASSWORD_FILE})"
export TMPDIR="/mnt/duplicity-pvc/tmp"
mkdir -p ${TMPDIR}

DEST="sftp://${FTPUSERNAME}@${FTPURL}/${FTPUSERNAME}"


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
    sshpass -e ssh-keyscan ${FTPURL} > ~/.ssh/known_hosts
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

    mkdir -p "$TMPDIR"

    export TMPDIR="$TMPDIR"
    rm -Rf ${HOME}/.cache/
    mkdir -p ${HOME}/.cache/duplicity

    log "Duplicity version:"
    duplicity --version

}

# --------------------------------------------------
# Backup
# --------------------------------------------------

backup() {

# /usr/bin/duplicity --no-restore-ownership --verbosity debug --allow-source-mismatch /home sftp://duplicity_test@omv.slainte.at/duplicity_test

    log "Starting backup"

    sshpass -e duplicity \
        --no-restore-ownership  \
        --verbosity ${VERBOSITY} \
        --allow-source-mismatch \
        "$SOURCE" \
        "$DEST"

    log "Backup completed successfully"

}

# --------------------------------------------------
# Check
# --------------------------------------------------

check() {

    log "Checking backup collection"

    sshpass -e duplicity \
        collection-status \
        "$DEST"

    log "Verifying backup data"

    sshpass -e duplicity \
        --no-restore-ownership  \
        --verbosity ${VERBOSITY} \
        --allow-source-mismatch \
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

    sshpass -e duplicity \
        --no-restore-ownership  \
        --force \
        --verbosity ${VERBOSITY} \
        --allow-source-mismatch \
        remove-older-than "$RETENTION" \
        "$DEST"

#/usr/bin/duplicity --no-restore-ownership --force --verbosity debug --allow-source-mismatch sftp://duplicity_test@omv.slainte.at/duplicity_test remove-older-than 1M

    log "Cleaning up unused backup files"

    sshpass -e duplicity \
        --no-restore-ownership \
        --force \
        --verbosity "${VERBOSITY}" \
        --allow-source-mismatch \
        "$DEST" \
        cleanup

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
############################################################################################
#
# Test-statments for duplicity backup script
#
############################################################################################

# sshpass -e ssh-keyscan omv.slainte.at >> ~/.ssh/known_hosts
# sshpass -e ssh -o StrictHostKeyChecking=no duplicity_test@omv

# #TMP_DIR="/mnt/duplicity-pvc/tmp"

# mkdir -p /mnt/duplicity-pvc/tmp
# #mkdir -p /mnt/duplicity-pvc/cache

# export TMPDIR=/mnt/duplicity-pvc/tmp
# #export XDG_CACHE_HOME=/mnt/duplicity-pvc/cache
# sshpass -e duplicity --verbosity info --allow-source-mismatch  /home sftp://duplicity_test@omv.slainte.at/duplicity_test

# sshpass -e duplicity --verbosity info /home sftp://duplicity@omv/duplicity_test

# ####
# id
# grep CapEff /proc/self/status
# touch /tmp/chown-test && chown duplicity:duplicity /tmp/chown-test
