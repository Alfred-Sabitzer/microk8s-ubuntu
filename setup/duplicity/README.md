https://zertrin.org/how-to/installation-and-configuration-of-duplicity-for-encrypted-sftp-remote-backup/


To use OpenMediaVault (OMV) as an NFS server for Duplicity backups, you need to configure an NFS share on your OMV server and then mount that share on your client machine where Duplicity is running. Finally, you'll configure Duplicity to use the mounted NFS share as the backup location. 
Here's a step-by-step guide:
1. Configure the NFS Share on OMV:
Access the OMV Web UI: Log in to your OpenMediaVault server through its web interface. 
Navigate to NFS: Go to "Services" -> "NFS". 
Create a new share: Click the "Add" button to create a new NFS share. 
Configure the share:
General Settings:
Name: Give your share a descriptive name (e.g., "duplicity-backup").
Path: Specify the directory on your OMV server that will be used as the backup location. This should be a directory you've created for this purpose. 
Description: Add a brief description for the share.
Access:
Clients: Add the IP address or hostname of the client machine where Duplicity will run. You can also use a network range (e.g., "192.168.1.0/24") for multiple clients. 
Permissions: Choose the appropriate permissions for the client. Typically, "Read/Write" is needed for Duplicity to function correctly. 
Advanced Settings: You may need to adjust advanced settings like "Sync" or "no_subtree_check" depending on your specific needs and network environment. 
Save the settings: Click "Save" to create the NFS share. 
Apply the changes: In the NFS service settings, click "Apply" to activate the new share. 
2. Mount the NFS Share on the Client Machine:
Install NFS client: If you haven't already, install the NFS client package on your client machine (e.g., using sudo apt-get install nfs-common on Debian/Ubuntu). 
Create a mount point: Create a directory on your client machine where you will mount the NFS share (e.g., sudo mkdir /mnt/omv_backup). 
Mount the share: Use the mount command to mount the NFS share: 
Code

    sudo mount -t nfs <omv_server_ip>:<omv_share_path> /mnt/omv_backup
Replace <omv_server_ip> with the IP address of your OMV server.
Replace <omv_share_path> with the path to the NFS share on the OMV server (e.g., /export/duplicity-backup).
/mnt/omv_backup is the mount point you created earlier. 
Verify the mount: Use the df -h command to check if the NFS share is mounted correctly. 
3. Configure Duplicity:
Use the mounted directory: In your Duplicity command, specify the mount point as the backup location (e.g., duplicity /path/to/your/data file:///mnt/omv_backup/duplicity_backup).
Example Duplicity command: 
Code

    duplicity --archive-dir /tmp/duplicity_cache /path/to/your/data file:///mnt/omv_backup/duplicity_backup
This command backs up the directory /path/to/your/data to the duplicity_backup directory within the NFS share mounted at /mnt/omv_backup. 





bronze badges
Add a comment
1

I migrate my lxc container by following.

Create a copy of your container if you don't want to stop it.

lxc copy <container> <container-export>
Publish your stop container to the local image registry

lxc publish <container-export> --alias <container-export>
Create a tarball from the image

lxc image export <container-export> <nameofTAR>
Copy the tarball to another server

scp nameoftar.tar.gz <username>@<ip>:/path-to-remote
After copying the tarball. Import the tar ball to local registry

lxc image import TARBALL --alias <container-export>
Start the container from the image.

lxc init my-export NEW-CONTAINER

