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


https://docs.upvest.co/products/tol/getting_started/pgp_keys/creating_pgp_keys

duplicity-test-695bbcd46d-wj57c:~$ gpg --full-generate-key
gpg (GnuPG) 2.4.9; Copyright (C) 2025 g10 Code GmbH
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

gpg: directory '/home/duplicity/.gnupg' created
Please select what kind of key you want:
   (1) RSA and RSA
   (2) DSA and Elgamal
   (3) DSA (sign only)
   (4) RSA (sign only)
   (9) ECC (sign and encrypt) *default*
  (10) ECC (sign only)
  (14) Existing key from card
Your selection? 9
Please select which elliptic curve you want:
   (1) Curve 25519 *default*
   (4) NIST P-384
   (6) Brainpool P-256
Your selection? 1
Please specify how long the key should be valid.
         0 = key does not expire
      <n>  = key expires in n days
      <n>w = key expires in n weeks
      <n>m = key expires in n months
      <n>y = key expires in n years
Key is valid for? (0) 0
Key does not expire at all
Is this correct? (y/N) y
                        
GnuPG needs to construct a user ID to identify your key.

Real name: duplicity
Email address: duplicity@slainte.at
Comment: Duplicity gpg-scheme      
You selected this USER-ID:   
    "duplicity (Duplicity gpg-scheme) <duplicity@slainte.at>"

Change (N)ame, (C)omment, (E)mail or (O)kay/(Q)uit? O
We need to generate a lot of random bytes. It is a good idea to perform
some other action (type on the keyboard, move the mouse, utilize the
disks) during the prime generation; this gives the random number
generator a better chance to gain enough entropy.
We need to generate a lot of random bytes. It is a good idea to perform
some other action (type on the keyboard, move the mouse, utilize the
disks) during the prime generation; this gives the random number
generator a better chance to gain enough entropy.
gpg: /home/duplicity/.gnupg/trustdb.gpg: trustdb created
gpg: directory '/home/duplicity/.gnupg/openpgp-revocs.d' created
gpg: revocation certificate stored as '/home/duplicity/.gnupg/openpgp-revocs.d/6A48945DD39EDDB6727B2120B19461E16227D80E.rev'
public and secret key created and signed.

pub   ed25519 2026-11-07 [SC]
      6A48945DD39EDDB6727B2120B19461E16227D80E
uid                      duplicity (Duplicity gpg-scheme) <duplicity@slainte.at>
sub   cv25519 2026-11-07 [E]

duplicity-test-695bbcd46d-wj57c:~$ 

duplicity-test-695bbcd46d-wj57c:~$ gpg --list-keys
gpg: checking the trustdb
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: depth: 0  valid:   1  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 1u
[keyboxd]
---------
pub   ed25519 2026-11-07 [SC]
      6A48945DD39EDDB6727B2120B19461E16227D80E
uid           [ultimate] duplicity (Duplicity gpg-scheme) <duplicity@slainte.at>
sub   cv25519 2026-11-07 [E]

duplicity-test-695bbcd46d-wj57c:~$ gpg --export --armor --output gpg.public.asc 6A48945DD39EDDB6727B2120B19461E16227D80E

duplicity-test-695bbcd46d-wj57c:~$ gpg --export-secret-keys --armor --output gpg.private_key.asc duplicity@slainte.at  
duplicity-test-695bbcd46d-wj57c:~$ 




export BACKEND_PASSWORD=$(cat /mnt/duplicity-backup-credentials/password )
duplicity --verbosity info /home sftp://duplicity@omv//home/user/duplicity_test

duplicity --verbosity info /home pexpect+ssh://duplicity@omv//home/user/duplicity_test

