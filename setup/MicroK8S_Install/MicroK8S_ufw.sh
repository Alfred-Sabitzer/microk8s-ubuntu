#!/bin/bash
############################################################################################
#
# Confgure UFW
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition

# You may need to configure your firewall to allow pod-to-pod and pod-to-internet communication:
sudo ufw --force reset
sudo ufw allow in on cni0 && sudo ufw allow out on cni0
sudo ufw default allow routed

# 192.168.178.36 10.1.77.0 fd43:93fa:6ec8:0:a00:27ff:fe1a:48b 2a0b:9e04:118f:5d80:a00:27ff:fe1a:48b
# Enable Connections from our internal network
for ip in $(hostname --all-ip-addresses)
do
  sudo ufw allow from ${ip}/24
done

# For sure, we bring our own definitions
cat <<EOF | sudo tee /etc/ufw/applications.d/openssh-server
[OpenSSH]
title=Secure shell server, an rshd replacement
description=OpenSSH is a free implementation of the Secure Shell protocol.
ports=22/tcp
EOF

cat <<EOF | sudo tee /etc/ufw/applications.d/nginx
[Nginx HTTP]
title=Web Server
description=Enable NGINX HTTP traffic
ports=80/tcp

[Nginx HTTPS]
title=Web Server (HTTPS)
description=Enable NGINX HTTPS traffic
ports=443/tcp

[Nginx Full]
title=Web Server (HTTP,HTTPS)
description=Enable NGINX HTTP and HTTPS traffic
ports=80,443/tcp
EOF

sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'

sudo ufw --force enable
# sudo ufw status numbered
sudo ufw status verbose
#
