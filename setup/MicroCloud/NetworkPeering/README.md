# Configuration of a Network Peering

Here are examples for working Network Peerings


```bash
# Peering has to be mutual
lxc network peer create Infrastructure infradefault default
lxc network peer create default infradefault Infrastructure

lxc network peer list Infrastructure
+--------------+-------------+-----------------+---------+
|     NAME     | DESCRIPTION |      PEER       |  STATE  |
+--------------+-------------+-----------------+---------+
| infradefault |             | default/default | CREATED |
+--------------+-------------+-----------------+---------+

lxc network peer list default
+--------------+-------------+------------------------+---------+
|     NAME     | DESCRIPTION |          PEER          |  STATE  |
+--------------+-------------+------------------------+---------+
| infradefault |             | default/Infrastructure | CREATED |
+--------------+-------------+------------------------+---------+
```
## Network Zones

For being able to forward requests, we create a network zone.

```bash
lxc network list
+----------------+----------+---------+-----------------+---------------------------+-------------+---------+---------+
|      NAME      |   TYPE   | MANAGED |      IPV4       |           IPV6            | DESCRIPTION | USED BY |  STATE  |
+----------------+----------+---------+-----------------+---------------------------+-------------+---------+---------+
| Infrastructure | ovn      | YES     | 10.139.121.1/24 | fd42:9391:4343:38fa::1/64 |             | 7       | CREATED |
+----------------+----------+---------+-----------------+---------------------------+-------------+---------+---------+
| UPLINK         | physical | YES     |                 |                           |             | 2       | CREATED |
+----------------+----------+---------+-----------------+---------------------------+-------------+---------+---------+
| br0            | bridge   | NO      |                 |                           |             | 1       |         |
+----------------+----------+---------+-----------------+---------------------------+-------------+---------+---------+
| br-int         | bridge   | NO      |                 |                           |             | 0       |         |
+----------------+----------+---------+-----------------+---------------------------+-------------+---------+---------+
| default        | ovn      | YES     | 10.0.219.1/24   | fd42:daa:bfe9:1725::1/64  |             | 6       | CREATED |
+----------------+----------+---------+-----------------+---------------------------+-------------+---------+---------+
| eno1           | physical | NO      |                 |                           |             | 0       |         |
+----------------+----------+---------+-----------------+---------------------------+-------------+---------+---------+
| lxdovn1        | bridge   | NO      |                 |                           |             | 0       |         |
+----------------+----------+---------+-----------------+---------------------------+-------------+---------+---------+
NetworkPeeing

lxc network zone create demo.example.net
lxc network zone create 121.139.10.in-addr.arpa


host fd42:9391:4343:38fa::1
Host 1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.a.f.8.3.3.4.3.4.1.9.3.9.2.4.d.f.ip6.arpa not found: 3(NXDOMAIN)

lxc network zone create a.f.8.3.3.4.3.4.1.9.3.9.2.4.d.f.ip6.arpa

lxc network zone list
+------------------------------------------+-------------+---------+
|                   NAME                   | DESCRIPTION | USED BY |
+------------------------------------------+-------------+---------+
| 121.139.10.in-addr.arpa                  |             | 0       |
+------------------------------------------+-------------+---------+
| a.f.8.3.3.4.3.4.1.9.3.9.2.4.d.f.ip6.arpa |             | 0       |
+------------------------------------------+-------------+---------+
| demo.example.net                         |             | 0       |
+------------------------------------------+-------------+---------+


lxc network set Infrastructure dns.zone.forward=demo.example.net
lxc network set Infrastructure dns.zone.reverse.ipv4=121.139.10.in-addr.arpa 
lxc network set Infrastructure dns.zone.reverse.ipv6=a.f.8.3.3.4.3.4.1.9.3.9.2.4.d.f.ip6.arpa

lxc network list
+----------------+----------+---------+-----------------+---------------------------+-------------+---------+---------+
|      NAME      |   TYPE   | MANAGED |      IPV4       |           IPV6            | DESCRIPTION | USED BY |  STATE  |
+----------------+----------+---------+-----------------+---------------------------+-------------+---------+---------+
| Infrastructure | ovn      | YES     | 10.139.121.1/24 | fd42:9391:4343:38fa::1/64 |             | 7       | CREATED |
+----------------+----------+---------+-----------------+---------------------------+-------------+---------+---------+
| UPLINK         | physical | YES     |                 |                           |             | 2       | CREATED |
+----------------+----------+---------+-----------------+---------------------------+-------------+---------+---------+
| br0            | bridge   | NO      |                 |                           |             | 1       |         |
+----------------+----------+---------+-----------------+---------------------------+-------------+---------+---------+
| br-int         | bridge   | NO      |                 |                           |             | 0       |         |
+----------------+----------+---------+-----------------+---------------------------+-------------+---------+---------+
| default        | ovn      | YES     | 10.0.219.1/24   | fd42:daa:bfe9:1725::1/64  |             | 6       | CREATED |
+----------------+----------+---------+-----------------+---------------------------+-------------+---------+---------+
| eno1           | physical | NO      |                 |                           |             | 0       |         |
+----------------+----------+---------+-----------------+---------------------------+-------------+---------+---------+
| lxdovn1        | bridge   | NO      |                 |                           |             | 0       |         |
+----------------+----------+---------+-----------------+---------------------------+-------------+---------+---------+


lxc config set core.dns_address 10.139.121.1:8853

#lxc config set core.dns_address 10.139.121.5:8853


lxc network zone list
+------------------------------------------+-------------+---------+
|                   NAME                   | DESCRIPTION | USED BY |
+------------------------------------------+-------------+---------+
| 121.139.10.in-addr.arpa                  |             | 1       |
+------------------------------------------+-------------+---------+
| a.f.8.3.3.4.3.4.1.9.3.9.2.4.d.f.ip6.arpa |             | 1       |
+------------------------------------------+-------------+---------+
| demo.example.net                         |             | 1       |
+------------------------------------------+-------------+---------+


lxc network zone show demo.example.net
name: demo.example.net
description: ""
config: {}
used_by:
- /1.0/networks/Infrastructure



lxc network zone set demo.example.net peers.ns1.address 10.139.121.5
lxc network zone set demo.example.net dns.nameservers ns1.demo.example.net


lxc network zone set 121.139.10.in-addr.arpa peers.ns1.address 10.139.121.5
lxc network zone set 121.139.10.in-addr.arpa dns.nameservers ns1.demo.example.net


lxc network zone set a.f.8.3.3.4.3.4.1.9.3.9.2.4.d.f.ip6.arpa peers.ns1.address 10.139.121.5
lxc network zone set a.f.8.3.3.4.3.4.1.9.3.9.2.4.d.f.ip6.arpa dns.nameservers ns1.demo.example.net


lxc network zone show 121.139.10.in-addr.arpa  
name: 121.139.10.in-addr.arpa
description: ""
config:
  dns.nameservers: ns1.demo.example.net
  peers.ns1.address: 10.139.121.5
used_by:
- /1.0/networks/Infrastructure


lxc network zone show a.f.8.3.3.4.3.4.1.9.3.9.2.4.d.f.ip6.arpa
name: a.f.8.3.3.4.3.4.1.9.3.9.2.4.d.f.ip6.arpa
description: ""
config:
  dns.nameservers: ns1.demo.example.net
  peers.ns1.address: 10.139.121.5
used_by:
- /1.0/networks/Infrastructure


lxc network zone show demo.example.net
name: demo.example.net
description: ""
config:
  dns.nameservers: ns1.demo.example.net
  peers.ns1.address: 10.139.121.5
used_by:
- /1.0/networks/Infrastructure


```


## References
- [lxd Dokumentation Network Peers](https://documentation.ubuntu.com/lxd/latest/howto/network_ovn_peers/#)
- [lxd Dokumentation Network Zones](https://documentation.ubuntu.com/lxd/latest/howto/network_zones/)
- [lxd Dokumentation on youtube](https://www.youtube.com/watch?v=2MqpJOogNVQ)


