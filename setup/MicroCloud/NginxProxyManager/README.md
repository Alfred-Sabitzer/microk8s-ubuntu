# NGINX Proxy Manager

https://nginxproxymanager.com/

Install a simple proxy manager based on https://github.com/ej52/proxmox-scripts/tree/main/apps/nginx-proxy-manager

 lxc config device add NginxTest myport80 proxy listen=tcp:0.0.0.0:80 connect=tcp:127.0.0.1:80 proxy_protocol=true
 lxc config device add NginxTest myport443 proxy listen=tcp:0.0.0.0:443 connect=tcp:127.0.0.1:443 proxy_protocol=true 
 
 lxc network load-balancer create [<remote>:]<network> [<listen_address>] [key=value...] [flags]
 lxc network load-balancer create bridgetest
 
 lxc network forward create ovn-tEST --allocate ipv4 target_address=10.224.32.5	


 lxc network load-balancer backend add [<remote>:]<network> <listen_address> <backend_name> <target_address> [<target_port(s)>] [flags]

alfred@k4:~$ lxc network load-balancer delete OVN 192.168.0.200 
alfred@k4:~$ lxc network load-balancer create OVN 192.168.0.200 
alfred@k4:~$ lxc network load-balancer backend add OVN 192.168.0.200 nginx 10.58.200.2
