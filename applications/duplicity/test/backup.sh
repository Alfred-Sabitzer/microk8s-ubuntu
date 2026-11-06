#!/usr/bin/env bash

set -Eeuo pipefail

# --------------------------------------------------
# Konfiguration über Umgebungsvariablen
# --------------------------------------------------

: "${S3_ENDPOINT:?S3_ENDPOINT fehlt}"
: "${S3_ACCESS_KEY_ID:?S3_ACCESS_KEY_ID fehlt}"
: "${S3_SECRET_ACCESS_KEY:?S3_SECRET_ACCESS_KEY fehlt}"
: "${S3_BUCKET:?S3_BUCKET fehlt}"

: "${SSHFS_REMOTE:?SSHFS_REMOTE fehlt}"
: "${SSHFS_REMOTE_PATH:?SSHFS_REMOTE_PATH fehlt}"

: "${PASSPHRASE:?PASSPHRASE für duplicity fehlt}"

S3_REGION="${S3_REGION:-us-east-1}"
BACKUP_PATH="${BACKUP_PATH:-/backup}"

S3_MOUNT="/mnt/s3"
SSHFS_MOUNT="/mnt/sshfs"

RCLONE_CONFIG="/tmp/rclone.conf"
RCLONE_PID=""
SSHFS_PID=""

# --------------------------------------------------
# Aufräumen beim Beenden
# --------------------------------------------------

cleanup() {
    echo "Beende Backup und entferne Mounts ..."

    if [[ -n "${SSHFS_PID}" ]]; then
        kill "${SSHFS_PID}" 2>/dev/null || true
    fi

    if [[ -n "${RCLONE_PID}" ]]; then
        kill "${RCLONE_PID}" 2>/dev/null || true
    fi

    sleep 1

    if mountpoint -q "${SSHFS_MOUNT}"; then
        fusermount3 -u "${SSHFS_MOUNT}" 2>/dev/null || true
    fi

    if mountpoint -q "${S3_MOUNT}"; then
        fusermount3 -u "${S3_MOUNT}" 2>/dev/null || true
    fi

    rm -f "${RCLONE_CONFIG}"
}

trap cleanup EXIT INT TERM

# --------------------------------------------------
# SSH-Konfiguration prüfen
# --------------------------------------------------

SSH_KEY="/run/secrets/id_ed25519"
SSH_KNOWN_HOSTS="/run/secrets/known_hosts"

if [[ ! -r "${SSH_KEY}" ]]; then
    echo "Fehler: SSH-Schlüssel ${SSH_KEY} fehlt."
    exit 1
fi

if [[ ! -r "${SSH_KNOWN_HOSTS}" ]]; then
    echo "Fehler: ${SSH_KNOWN_HOSTS} fehlt."
    exit 1
fi

# --------------------------------------------------
# rclone konfigurieren
# --------------------------------------------------

umask 077

cat > "${RCLONE_CONFIG}" <<EOF
[s3remote]
type = s3
provider = Other
env_auth = false
access_key_id = ${S3_ACCESS_KEY_ID}
secret_access_key = ${S3_SECRET_ACCESS_KEY}
endpoint = ${S3_ENDPOINT}
region = ${S3_REGION}
EOF

# --------------------------------------------------
# Mount-Verzeichnisse vorbereiten
# --------------------------------------------------

mkdir -p "${S3_MOUNT}" "${SSHFS_MOUNT}"

# --------------------------------------------------
# S3-Bucket mounten
# --------------------------------------------------

echo "Mounten des S3-Buckets ..."

rclone mount \
    "s3remote:${S3_BUCKET}" \
    "${S3_MOUNT}" \
    --config "${RCLONE_CONFIG}" \
    --read-only \
    --vfs-cache-mode off \
    --log-level INFO &

RCLONE_PID=$!

# --------------------------------------------------
# SSHFS mounten
# --------------------------------------------------

echo "Mounten des SSHFS-Laufwerks ..."

sshfs \
    -o reconnect \
    -o ServerAliveInterval=15 \
    -o ServerAliveCountMax=3 \
    -o StrictHostKeyChecking=yes \
    -o "UserKnownHostsFile=${SSH_KNOWN_HOSTS}" \
    -o "IdentityFile=${SSH_KEY}" \
    -o IdentitiesOnly=yes \
    -o BatchMode=yes \
    "${SSHFS_REMOTE}:${SSHFS_REMOTE_PATH}" \
    "${SSHFS_MOUNT}" &

SSHFS_PID=$!

# --------------------------------------------------
# Auf Mounts warten
# --------------------------------------------------

wait_for_mount() {
    local path="$1"
    local pid="$2"
    local timeout=60
    local elapsed=0

    until mountpoint -q "${path}"; do
        if ! kill -0 "${pid}" 2>/dev/null; then
            echo "Fehler: Mount-Prozess für ${path} wurde beendet."
            return 1
        fi

        if (( elapsed >= timeout )); then
            echo "Fehler: Timeout beim Mounten von ${path}."
            return 1
        fi

        sleep 1
        ((elapsed += 1))
    done
}

wait_for_mount "${S3_MOUNT}" "${RCLONE_PID}"
wait_for_mount "${SSHFS_MOUNT}" "${SSHFS_PID}"

echo "Beide Dateisysteme sind gemountet."

# --------------------------------------------------
# SSHFS-Zielverzeichnis vorbereiten
# --------------------------------------------------

mkdir -p "${SSHFS_MOUNT}${BACKUP_PATH}"

# --------------------------------------------------
# Zugriff testen
# --------------------------------------------------

echo "Prüfe S3-Zugriff ..."
ls -la "${S3_MOUNT}" >/dev/null

echo "Prüfe SSHFS-Zugriff ..."
test -d "${SSHFS_MOUNT}${BACKUP_PATH}"

# --------------------------------------------------
# Duplicity-Backup
# --------------------------------------------------

echo "Starte duplicity ..."

duplicity \
    --verbosity info \
    "${S3_MOUNT}" \
    "file://${SSHFS_MOUNT}${BACKUP_PATH}"

echo "Backup erfolgreich abgeschlossen."