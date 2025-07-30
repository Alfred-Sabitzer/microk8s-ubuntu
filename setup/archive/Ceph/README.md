# Ceph Cluster Automation

## Project Overview
Automates installation, configuration, and removal of a Ceph cluster using Ansible scripts and playbooks.

## Prerequisites
- Ubuntu 22.04+ on all nodes
- Passwordless sudo for the user running scripts
- Ansible installed and configured
- SSH keys distributed to all nodes

## Usage

### Install Ceph
```bash
chmod +x Ceph_Install.sh
./Ceph_Install.sh
```

### Distribute SSH Keys
```bash
chmod +x copy_id_pub.sh
./copy_id_pub.sh
```

### Remove Ceph
```bash
chmod +x Ceph_delete.sh
./Ceph_delete.sh
```

## Configuration
- Adjust inventory and hostnames in Ansible as needed.
- Edit playbooks to match your environment.

## Testing
- Check Ceph status: `sudo ceph status`
- Verify services: `systemctl status ceph*`

## Troubleshooting
- Check Ansible output for errors.
- Ensure SSH connectivity between nodes.
- Verify sudo permissions.

## Cleanup
- Use `Ceph_delete.sh` to remove all Ceph components and data.

## References
- [Ceph Installation Guide](https://docs.ceph.com/en/latest/cephadm/install/)
- [Ceph Operations Guide](https://docs.ceph.com/en/reef/cephadm/operations/#osd)
- [Ceph Deply a Cluster](https://docs.ceph.com/en/reef/cephadm/install/#cephadm-deploying-new-cluster)
- [MicroCeph Documentation](https://canonical-microceph.readthedocs-hosted.com/en/squid-stable/)

## Security Notes
- Do not store sensitive keys or passwords in scripts or playbooks.
- Ensure SSH keys are distributed securely.

## Operations Example

### Now prepare your disks 

    check /etc/fstab
    delete partitions with fdisk
   
    
    alfred@k1:~$ sudo fdisk /dev/nvme0n1

    Welcome to fdisk (util-linux 2.39.3).
    Changes will remain in memory only, until you decide to write them.
    Be careful before using the write command.

    This disk is currently in use - repartitioning is probably a bad idea.
    It's recommended to umount all file systems, and swapoff all swap
    partitions on this disk.


    Command (m for help): p

    Disk /dev/nvme0n1: 476.94 GiB, 512110190592 bytes, 1000215216 sectors
    Disk model: SAMSUNG MZVLW512HMJP-000H1              
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disklabel type: gpt
    Disk identifier: 30F6DDCB-4A26-4B1D-A6EF-6B8128144B58

    Device             Start        End   Sectors   Size Type
    /dev/nvme0n1p1      2048    2203647   2201600     1G EFI System
    /dev/nvme0n1p2   2203648   12689407  10485760     5G Linux filesystem
    /dev/nvme0n1p3  12689408  222404607 209715200   100G Linux filesystem
    /dev/nvme0n1p4 222404608 1000214527 777809920 370.9G Linux filesystem

    Command (m for help): m

    # Help:
    #
    #   GPT
    #    M   enter protective/hybrid MBR
    #
    #   Generic
    #    d   delete a partition
    #    F   list free unpartitioned space
    #    l   list known partition types
    #    n   add a new partition
    #    p   print the partition table
    #    t   change a partition type
    #    v   verify the partition table
    #    i   print information about a partition
    #
    #   Misc
    #    m   print this menu
    #    x   extra functionality (experts only)
    #
    #   Script
    #    I   load disk layout from sfdisk script file
    #    O   dump disk layout to sfdisk script file
    #
    #   Save & Exit
    #    w   write table to disk and exit
    #    q   quit without saving changes
    #
    #   Create a new label
    #    g   create a new empty GPT partition table
    #    G   create a new empty SGI (IRIX) partition table
    #    o   create a new empty MBR (DOS) partition table
    #    s   create a new empty Sun partition table
    #
#### Delete what is there
    #
    Command (m for help): d
    Partition number (1-4, default 4): 4

    Partition 4 has been deleted.

    Command (m for help): w
    The partition table has been altered.
    Failed to remove partition 4 from system: Device or resource busy
    #
    The kernel still uses the old partitions. The new table will be used at the next reboot. 
    Syncing disks.

    # alfred@k1:~$ A
    #
#### Create a new partition
    #
    Command (m for help): n
    Partition number (4-128, default 4): 4
    First sector (222404608-1000215182, default 222404608): 
    Last sector, +/-sectors or +/-size{K,M,G,T,P} (222404608-1000215182, default 1000214527): 
    
    Created a new partition 4 of type 'Linux filesystem' and of size 370.9 GiB.
    Partition #4 contains a LVM2_member signature.
    
    Do you want to remove the signature? [Y]es/[N]o: Y
    
    The signature will be removed by a write command.
    
    Command (m for help): w
    The partition table has been altered.
    Syncing disks.
    
#### check and add to ceph

    alfred@k1:~$ lsblk
    NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
    sr0          11:0    1  1024M  0 rom  
    nvme0n1     259:0    0 476.9G  0 disk 
    ├─nvme0n1p1 259:1    0     1G  0 part /boot/efi
    ├─nvme0n1p2 259:2    0     5G  0 part /boot
    ├─nvme0n1p3 259:3    0   100G  0 part /var/lib/containers/storage/overlay
    │                                     /
    └─nvme0n1p4 259:4    0 370.9G  0 part 
    
    alfred@k1:~$ sudo pvcreate /dev/nvme0n1p4
      Physical volume "/dev/nvme0n1p4" successfully created.
    alfred@k1:~$ sudo vgcreate  $(hostname -s) /dev/nvme0n1p4
      Volume group "k1" successfully created
    alfred@k1:~$ sudo lvcreate -n $(hostname -s) -l 100%FREE $(hostname -s)
    WARNING: ceph_bluestore signature detected on /dev/k1/k1 at offset 0. Wipe it? [y/n]: y
      Wiping ceph_bluestore signature on /dev/k1/k1.
      Logical volume "k1" created.
    alfred@k1:~$ lsblk
    NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
    sr0          11:0    1  1024M  0 rom  
    nvme0n1     259:0    0 476.9G  0 disk 
    ├─nvme0n1p1 259:1    0     1G  0 part /boot/efi
    ├─nvme0n1p2 259:2    0     5G  0 part /boot
    ├─nvme0n1p3 259:3    0   100G  0 part /var/lib/containers/storage/overlay
    │                                     /
    └─nvme0n1p4 259:4    0 370.9G  0 part 
      └─k1-k1   252:0    0 370.9G  0 lvm  
    

OSD are managed best within the dashboard
https://docs.ceph.com/en/reef/cephadm/operations/#osd
