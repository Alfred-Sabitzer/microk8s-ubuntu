# Configuration of a Load Balancer

Here are examples for working Load Balancers

```bash
lxc network load-balancer create default 192.168.0.150
lxc network load-balancer backend add default 192.168.0.150 nginxtest 10.0.219.3
lxc network load-balancer port add default 192.168.0.150 tcp 80 nginxtest
```
Load Balancer for Nginxproxy Manager

```bash
lxc network load-balancer create Infrastructure 192.168.0.160
lxc network load-balancer backend add Infrastructure 192.168.0.160 nginxproxymanager 10.139.121.2
lxc network load-balancer port add Infrastructure 192.168.0.160 tcp 80 nginxproxymanager
lxc network load-balancer port add Infrastructure 192.168.0.160 tcp 443 nginxproxymanager
```

## References
- [lxd Dokumentation](https://documentation.ubuntu.com/lxd/stable-5.21/howto/network_load_balancers/)


