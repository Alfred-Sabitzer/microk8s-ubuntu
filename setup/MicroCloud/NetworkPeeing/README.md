# Configuration of a Network Peering

Here are examples for working Network Peerings

```bash
# Peering has to be mutual
lxc network peer create Infrastructure infradefault default
lxc network peer create default infradefault Infrastructure
```

Results will look like this

```bash
lxc network peer create Infrastructure infradefault default
Network peer infradefault pending (please complete mutual peering on peer network)
lxc network peer create default infradefault Infrastructure
Network peer infradefault created

root@micro4:~# lxc network peer list Infrastructure
+--------------+-------------+-----------------+---------+
|     NAME     | DESCRIPTION |      PEER       |  STATE  |
+--------------+-------------+-----------------+---------+
| infradefault |             | default/default | CREATED |
+--------------+-------------+-----------------+---------+

root@micro4:~# lxc network peer list default
+--------------+-------------+------------------------+---------+
|     NAME     | DESCRIPTION |          PEER          |  STATE  |
+--------------+-------------+------------------------+---------+
| infradefault |             | default/Infrastructure | CREATED |
+--------------+-------------+------------------------+---------+
```

## References
- [lxd Dokumentation Network Peers](https://documentation.ubuntu.com/lxd/latest/howto/network_ovn_peers/#)
- [lxd Dokumentation Network Zones](https://documentation.ubuntu.com/lxd/latest/howto/network_zones/)
- [lxd Dokumentation on youtube](https://www.youtube.com/watch?v=2MqpJOogNVQ)



