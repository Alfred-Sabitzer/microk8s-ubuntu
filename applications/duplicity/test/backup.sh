#!/usr/bin/env bash

mkdir ~/.ssh
cp /mnt/duplicity-ssh/id_ed25519  ~/.ssh/id_ed25519
chmod 600 ~/.ssh/id_ed25519 
cp /mnt/duplicity-ssh/id_ed25519.pub ~/.ssh/id_ed25519.pub
chmod 644 ~/.ssh/id_ed25519.pub
ssh-keyscan omv >> ~/.ssh/known_hosts

# # 3. Eine globale SSH-Konfiguration für "omv" schreiben
# cat <<EOF > ~/.ssh/config
# Host omv
#     StrictHostKeyChecking no
#     UserKnownHostsFile /dev/null
#     BatchMode no
# EOF
# chmod 600 ~/.ssh/config


cat <<EOF > ~/.ssh/config
Host omv
    HostName omv.slainte.at
    User duplicity
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    IdentitiesOnly yes
EOF
chmod 600 ~/.ssh/config

# This script is used to test duplicity backup functionality in a Kubernetes environment. It sets up the necessary environment variables, imports GPG keys, and runs duplicity commands to perform backups and restores.
# import GPG keys for duplicity
gpg --list-keys
cat /mnt/duplicity-backup-credentials/password | gpg --import --batch /mnt/duplicity-backup-credentials/gpg.private_key.asc 
gpg --list-keys

#cat /mnt/duplicity-backup-credentials/password | gpg -c --armor --batch --passphrase-fd 0 test.txt 
#cat /mnt/duplicity-backup-credentials/password | gpg -d -o d.txt --batch --passphrase-fd 0 test.txt.asc 

mkdir -p /mnt/duplicity-pvc/tmp
export TMPDIR=/mnt/duplicity-pvc/tmp

export PASSPHRASE=$(cat /mnt/duplicity-backup-credentials/password)
export BACKEND_PASSWORD=$(cat /mnt/duplicity-backup-credentials/password )
export RSYNC_PASSWORD=$(cat /mnt/duplicity-backup-credentials/password)
export SSHPASS=$(cat /mnt/duplicity-backup-credentials/password)

#sshpass -e ssh -o StrictHostKeyChecking=no omv
sshpass -e duplicity --verbosity info /home sftp://duplicity@omv/duplicity_test
