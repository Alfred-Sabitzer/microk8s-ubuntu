# DNS Resolution - nsd

We will use dnsmasq for our purposes.
We will assigne a fixed ip-adress within this network

```bash
ci-info: +++++++++++++++++++++++++++++++++++++++++++++Net device info++++++++++++++++++++++++++++++++++++++++++++++
ci-info: +--------+------+-------------------------------------------+---------------+--------+-------------------+
ci-info: | Device |  Up  |                  Address                  |      Mask     | Scope  |     Hw-Address    |
ci-info: +--------+------+-------------------------------------------+---------------+--------+-------------------+
ci-info: |  eth0  | True |                10.139.121.5               | 255.255.255.0 | global | 00:16:3e:81:28:1c |
ci-info: |  eth0  | True | fd42:9391:4343:38fa:216:3eff:fe81:281c/64 |       .       | global | 00:16:3e:81:28:1c |
ci-info: |  eth0  | True |        fe80::216:3eff:fe81:281c/64        |       .       |  link  | 00:16:3e:81:28:1c |
ci-info: |   lo   | True |                 127.0.0.1                 |   255.0.0.0   |  host  |         .         |
ci-info: |   lo   | True |                  ::1/128                  |       .       |  host  |         .         |
ci-info: +--------+------+-------------------------------------------+---------------+--------+-------------------+
ci-info: ++++++++++++++++++++++++++++++Route IPv4 info++++++++++++++++++++++++++++++
ci-info: +-------+--------------+--------------+---------------+-----------+-------+
ci-info: | Route | Destination  |   Gateway    |    Genmask    | Interface | Flags |
ci-info: +-------+--------------+--------------+---------------+-----------+-------+
ci-info: |   0   |   0.0.0.0    | 10.139.121.1 |    0.0.0.0    |    eth0   |   UG  |
ci-info: |   1   | 10.139.121.0 |   0.0.0.0    | 255.255.255.0 |    eth0   |   U   |
ci-info: +-------+--------------+--------------+---------------+-----------+-------+
ci-info: ++++++++++++++++++++++++++++++++++Route IPv6 info++++++++++++++++++++++++++++++++++
ci-info: +-------+--------------------------+--------------------------+-----------+-------+
ci-info: | Route |       Destination        |         Gateway          | Interface | Flags |
ci-info: +-------+--------------------------+--------------------------+-----------+-------+
ci-info: |   0   | fd42:9391:4343:38fa::/64 |            ::            |    eth0   |   U   |
ci-info: |   1   |        fe80::/64         |            ::            |    eth0   |   U   |
ci-info: |   2   |           ::/0           | fe80::216:3eff:fe5a:a9da |    eth0   |  UGe  |
ci-info: |   4   |          local           |            ::            |    eth0   |   U   |
ci-info: |   5   |          local           |            ::            |    eth0   |   U   |
ci-info: |   6   |        multicast         |            ::            |    eth0   |   U   |
ci-info: +-------+--------------------------+--------------------------+-----------+-------+
```
dnsmasq is needed for being able to configure networkpeering.

## References

- [nsd Setup](https://wiki.alpinelinux.org/wiki/Setting_up_nsd_DNS_server)
- [nsd setup generell](https://ipv6.rs/tutorial/Alpine_Linux_Latest/NSD/)
- [lxd Dokumentation on youtube](https://www.youtube.com/watch?v=2MqpJOogNVQ)


