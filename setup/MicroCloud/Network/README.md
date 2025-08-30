# Setup correct Network

See https://netplan.readthedocs.io/en/stable/examples/#how-to-configure-network-bridges
See https://askubuntu.com/questions/1491165/how-to-bridge-an-lxd-network-for-internet-access
See https://gist.github.com/berndbausch/a6835150c7a26c88048763c0bd739be6 

By default we get 

    +---------+----------+---------+------+------+-------------+---------+---------+
    |  NAME   |   TYPE   | MANAGED | IPV4 | IPV6 | DESCRIPTION | USED BY |  STATE  |
    +---------+----------+---------+------+------+-------------+---------+---------+
    | br-int  | bridge   | NO      |      |      |             | 0       |         |
    +---------+----------+---------+------+------+-------------+---------+---------+
    | eno1    | physical | NO      |      |      |             | 6       |         |
    +---------+----------+---------+------+------+-------------+---------+---------+
    | lxdfan0 | bridge   | YES     |      |      |             | 3       | CREATED |
    +---------+----------+---------+------+------+-------------+---------+---------+

But br-int is not well configured.
We will improve this by setting it up correct, following the instructions from the tutorial.

```yaml
network:
  version: 2
  ethernets:
    eno1:
      dhcp4: true
      dhcp6: true

  bridges:
    bridge0:
      interfaces: [eno1]
      dhcp4: true
      dhcp6: true
```

This is the setting for the bridge in /etc/netplan/50-cloud-init.yaml
This yaml has to be applied on all nodes. Test it first with 

````bash
sudo netplan apply
````
If this works, then try it on all other nodes.

The corresponding ansible yaml is

```yaml
-
  name: 'Playbook for applying network-bridge'
  hosts: all
  become: True
  become_method: sudo
  tasks:
    - name: copying 50-cloud-init.yaml
      become: true
      copy:
        src: 50-cloud-init.yaml
        dest: /etc/netplan/50-cloud-init.yaml
        owner: root
        group: root
        mode: 0600
    - name: "Apply Netplan"
      ansible.builtin.shell: sudo netplan apply
      args:
        executable: /bin/bash        
    - name: Reboot machine and send a message
      ansible.builtin.reboot:
        msg: "Rebooting machine in 5 seconds"
    - name: Wait 300 seconds, but only start checking after 15 seconds
      ansible.builtin.wait_for_connection:
        delay: 15
        timeout: 300
```


````bash
#!/bin/bash
# Rebooted alles nodes im Cluster
ansible-playbook -v ./set_cloud_init.yaml
````
The corresponding ansible yaml is

```yaml
-
  name: 'Playbook for applying network-bridge'
  hosts: all
  become: True
  become_method: sudo
  tasks:
    - name: copying 50-cloud-init.yaml
      become: true
      copy:
        src: 50-cloud-init.yaml
        dest: /etc/netplan/50-cloud-init.yaml
        owner: root
        group: root
        mode: 0600
    - name: "Apply Netplan"
      ansible.builtin.shell: sudo netplan apply
      args:
        executable: /bin/bash        
    - name: Reboot machine and send a message
      ansible.builtin.reboot:
        msg: "Rebooting machine in 5 seconds"
    - name: Wait 300 seconds, but only start checking after 15 seconds
      ansible.builtin.wait_for_connection:
        delay: 15
        timeout: 300
```

After this, all nodes have the same config.

Then assigne the bridge config. See https://cmngoal.com/lxc-cheatsheet

````bash
# List Networks
lxc network list
lxc network info br-int
lxc network info eno1
lxc network info lxdfan0 
lxc network info bridge0
# Create a new bridge network
lxc network delete bridge0
lxc network create bridge0  --target k1

# Configure bridge network settings
lxc network set bridge0 ipv4.address=192.168.0.1/24
lxc network set bridge0 ipv4.nat=true
lxc network set bridge0 ipv4.dhcp=true
lxc network set bridge0 ipv4.dhcp.ranges=192.168.0.10-192.168.0.190


````
