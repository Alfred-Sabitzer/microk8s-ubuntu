# ansible Configuration

See https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html

This script will help to automate configuration work for the k8s-cluster.

For proper work configure your local account as follows:

```bash
# Allow members of group sudo to execute any command
%sudo   ALL=(ALL:ALL) NOPASSWD:ALL
```

This is necessary to execute sudo commands without password prompt.

```bash
sudo usermod -aG sudo alfred
```

So user alfred is now member of the sudo-group and can execute commands.

