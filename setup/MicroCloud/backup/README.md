# MicroCloud Backup

We will use sshfs mounted directories and duplicity for encrypting the backups.
A backup-user is available on all machines with the appropriate rights to read the directories.


## Security Notes
- Ensure SSH keys and sudo access are managed securely.
- Review disk encryption configuration for compliance with your security policies.


## References
- [Backup Script](https://www.cyberciti.biz/faq/how-to-backup-and-restore-lxd-containers/)
- [Proxmox Scripts](https://tteck.github.io/Proxmox/#database)
- [duplicity usage](https://help.ubuntu.com/community/DuplicityBackupHowto)
