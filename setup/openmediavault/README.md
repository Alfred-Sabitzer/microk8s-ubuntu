# Setup and Operation of OpenMediaVault (OMV)

This document provides a comprehensive guide to setting up and operating OpenMediaVault (OMV) https://www.openmediavault.org/, an open-source NAS (Network-Attached Storage) solution. It is tailored for home labs, SOHO environments, and small enterprise use cases. We also integrate OMV into a Kubernetes-ready infrastructure using MicroK8s.

# Tool Description

OpenMediaVault (OMV) is a Debian-based open-source NAS operating system designed for ease of use and extensibility. It supports services such as:
- SMB/CIFS
- FTP/SFTP
- NFS
- Rsync
- iSCSI

OMV provides a web-based interface and plugin architecture for extensibility.

##  Advantages

- User-friendly web interface
- Plugin architecture enables extensibility
- Active and supportive community
- Lightweight and efficient
- Debian base allows apt-based customization

## Disadvantages

- Limited hardware compatibility
- Some features are plugin-dependent
- May require manual configuration for custom use
- Not designed for large-scale enterprise use
- Default security features are minimal


# Installation Instructions

Follow briefly the instructions on https://wiki.omv-extras.org/doku.php?id=omv7:raspberry_pi_install 
On the started image execute

````bash
sudo raspi-config
sudo apt-get update
sudo apt-get upgrade -y 

wget -O - https://github.com/OpenMediaVault-Plugin-Developers/installScript/raw/master/preinstall | sudo bash
sudo reboot
wget -O - https://github.com/OpenMediaVault-Plugin-Developers/installScript/raw/master/install | sudo bash
````

When Server is up, login and configure it according to your needs.
