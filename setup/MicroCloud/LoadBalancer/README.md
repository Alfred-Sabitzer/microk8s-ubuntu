# Configuration of a Load Balancer


 
lxc network load-balancer create [<remote>:]<network> [<listen_address>] [key=value...] [flags]
lxc network load-balancer create bridgetest
 
lxc network forward create ovn-tEST --allocate ipv4 target_address=10.224.32.5	


lxc network load-balancer backend add [<remote>:]<network> <listen_address> <backend_name> <target_address> [<target_port(s)>] [flags]

lxc network load-balancer delete default 192.168.0.200 
lxc network load-balancer create default 192.168.0.200 
lxc network load-balancer backend add default 192.168.0.200 nginx 10.239.150.2
