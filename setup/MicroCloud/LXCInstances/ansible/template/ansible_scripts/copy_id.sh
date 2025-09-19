#!/bin/bash
############################################################################################
# generate hosts file based on running containers
############################################################################################
#shopt -o -s errexit # Terminates  the shell script if a command returns an error code.
#shopt -o -s xtrace  # Displays each command before it is executed.
shopt -o -s nounset  # No Variables without definition
#

echo "# copy id" > /tmp/copy_id.sh
sudo lxc list --columns=n --format csv > /tmp/instances.txt
while IFS= read -r line; do
    echo "sudo lxc file push /home/ansible/scripts/id_ed25519.pub ${line}/home/ansible/.ssh/authorized_keys" >> /tmp/copy_id.sh
    echo "sudo lxc exec ${line} chmod 0600 /home/ansible/.ssh/authorized_keys " >> /tmp/copy_id.sh
    echo "echo $line authorized" >> /tmp/copy_id.sh
done < /tmp/instances.txt
chmod 755 /tmp/copy_id.sh
/tmp/copy_id.sh
#
