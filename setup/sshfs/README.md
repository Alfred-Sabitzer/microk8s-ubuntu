# SSHFS

There are a lot of discussions in the internet, comparing NFS, SMB and sshfs
NFS might be more stable in 7/24 and heavy-duty environments.
For temporary connection (which is our case for backups) sshfs is easiert to handle.

# Strategy

For every Backup-directory we will open an individual sshfs-connection. Our backups will be done
with duplicity (and every directoy has got its own encryption key).

## References
- [Performance comparison](https://blog.ja-ke.tech/2019/08/27/nas-performance-sshfs-nfs-smb.html)
- [Tech comparison](https://www.admin-magazine.com/HPC/Articles/Shared-Storage-with-NFS-and-SSHFS)
- [nfs usage](https://blog.ddavo.me/posts/tutorials/migrating-from-sshfs-to-nfs/)
- [duplicity usage](https://help.ubuntu.com/community/DuplicityBackupHowto)
