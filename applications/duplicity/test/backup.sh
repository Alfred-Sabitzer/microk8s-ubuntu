#!/usr/bin/env bash

# This script is used to test duplicity backup functionality in a Kubernetes environment. It sets up the necessary environment variables, imports GPG keys, and runs duplicity commands to perform backups and restores.
# import GPG keys for duplicity
gpg --list-keys
cat /mnt/duplicity-backup-credentials/password | gpg --import --batch /mnt/duplicity-backup-credentials/gpg.private_key.asc 
gpg --list-keys

#cat /mnt/duplicity-backup-credentials/password | gpg -c --armor --batch --passphrase-fd 0 test.txt 
#cat /mnt/duplicity-backup-credentials/password | gpg -d -o d.txt --batch --passphrase-fd 0 test.txt.asc 


export PASSPHRASE=$(cat /mnt/duplicity-backup-credentials/password)
export BACKEND_PASSWORD=$(cat /mnt/duplicity-backup-credentials/password )
export RSYNC_PASSWORD=$(cat /mnt/duplicity-backup-credentials/password)

duplicity --verbosity info --temproot /home/duplicity/tmp /home rsync://duplicity@omv//home/user/duplicity_test

#