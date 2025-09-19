#!/bin/bash
############################################################################################
# generate hosts file based on running containers
############################################################################################
#shopt -o -s errexit # Terminates  the shell script if a command returns an error code.
#shopt -o -s xtrace  # Displays each command before it is executed.
shopt -o -s nounset  # No Variables without definition
#
cat << EOF > /tmp/hosts
# generated hosts file
127.0.1.1	ansible
127.0.0.1	localhost localhost.localdomain
::1		    localhost localhost.localdomain

#
# physical nodes
#
192.168.0.191   micro1  micro1.slainte.at
192.168.0.192   micro2  micro2.slainte.at
192.168.0.193   micro3  micro3.slainte.at
192.168.0.194   micro4  micro4.slainte.at
#
# lxc instances
#
EOF
#
while read line; do  
    ipv4=$(lxc list $line --columns=4 --format csv | grep -i eth0)
    ipv4=${ipv4% *}
    if [ -z "$ipv4" ]; then
        ipv4="127.0.0.99"
    fi
    echo "$ipv4 $line $line.lxc" >> /tmp/hosts
done < <(lxc list --columns=n --format csv)
#