# ansible Setup

To set up Ansible, you need to install it on a control node and configure it to manage your target hosts. This involves installing Ansible, setting up SSH keys for secure connections, creating an inventory file, and optionally setting up an Ansible configuration file. 

Here's a more detailed breakdown:

## Install Ansible:

    Control Node Setup:
    Identify a machine to act as your Ansible control node. This machine will be used to run Ansible commands and playbooks. 

    See as well https://docs.ansible.com/ansible/latest/getting_started/index.html and https://docs.ansible.com/ansible/latest/installation_guide/installation_distros.html#installing-ansible-on-ubuntu 

### Installation Methods:

    Package Managers: Use your system's package manager (e.g., apt for Ubuntu, yum for CentOS/RHEL, brew for macOS) to install Ansible. 

pip: If you have Python and pip installed, you can use pip install ansible. 
From Source: For development or access to the latest features, you can install from source according to the Ansible documentation. 

### Verification:

After installation, verify the installation by checking the Ansible version using ansible --version. 

## Configure SSH Keys:

    Key Generation:
    Generate an SSH key pair on your control node if you don't already have one. This allows secure, passwordless access to your managed nodes.
    Key Copying:
    Copy the public key to the authorized_keys file on each of your managed nodes. 

## Create an Inventory File:

    Inventory File: Create an inventory file (e.g., hosts or inventory.ini) that lists the managed nodes (servers) you want Ansible to manage.
    Host Groups: You can group hosts together in your inventory for easier targeting in playbooks.
    Example: 

### Code

    [webservers]
    webserver1.example.com
    webserver2.example.com
    
    [databases]
    dbserver1.example.com
    dbserver2.example.com

### (Optional) Configure Ansible:

    ansible.cfg:
    Create an ansible.cfg file in the same directory as your inventory or in your home directory to configure Ansible's behavior.
    Settings:
    This file can contain settings like the inventory file location, SSH connection settings, and default modules. 

### Test the Setup:

    Ping Module: Use the ansible all -m ping command to test the connection to all hosts in your inventory.
    Verification: Ensure that Ansible can successfully communicate with your managed nodes. 
