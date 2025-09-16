# DNS Resolution - ns1

Follow the example on youtube [lxd Dokumentation on youtube](https://www.youtube.com/watch?v=2MqpJOogNVQ)

We need some network configuration.

````bash
[19849.006856] cloud-init[137]: ci-info: +++++++++++++++++++++++++++++++++++++++++++++Net device info++++++++++++++++++++++++++++++++++++++++++++++
[19849.006925] cloud-init[137]: ci-info: +--------+------+-------------------------------------------+---------------+--------+-------------------+
[19849.006962] cloud-init[137]: ci-info: | Device |  Up  |                  Address                  |      Mask     | Scope  |     Hw-Address    |
[19849.007008] cloud-init[137]: ci-info: +--------+------+-------------------------------------------+---------------+--------+-------------------+
[19849.007076] cloud-init[137]: ci-info: |  eth0  | True |                10.139.121.5               | 255.255.255.0 | global | 00:16:3e:0d:df:d0 |
[19849.007113] cloud-init[137]: ci-info: |  eth0  | True | fd42:9391:4343:38fa:216:3eff:fe0d:dfd0/64 |       .       | global | 00:16:3e:0d:df:d0 |
[19849.007147] cloud-init[137]: ci-info: |  eth0  | True |        fe80::216:3eff:fe0d:dfd0/64        |       .       |  link  | 00:16:3e:0d:df:d0 |
[19849.007185] cloud-init[137]: ci-info: |   lo   | True |                 127.0.0.1                 |   255.0.0.0   |  host  |         .         |
[19849.007232] cloud-init[137]: ci-info: |   lo   | True |                  ::1/128                  |       .       |  host  |         .         |
[19849.007271] cloud-init[137]: ci-info: +--------+------+-------------------------------------------+---------------+--------+-------------------+
[19849.007311] cloud-init[137]: ci-info: +++++++++++++++++++++++++++++++Route IPv4 info+++++++++++++++++++++++++++++++
[19849.007346] cloud-init[137]: ci-info: +-------+--------------+--------------+-----------------+-----------+-------+
[19849.007385] cloud-init[137]: ci-info: | Route | Destination  |   Gateway    |     Genmask     | Interface | Flags |
[19849.007419] cloud-init[137]: ci-info: +-------+--------------+--------------+-----------------+-----------+-------+
[19849.007455] cloud-init[137]: ci-info: |   0   |   0.0.0.0    | 10.139.121.1 |     0.0.0.0     |    eth0   |   UG  |
[19849.007493] cloud-init[137]: ci-info: |   1   | 10.139.121.0 |   0.0.0.0    |  255.255.255.0  |    eth0   |   U   |
[19849.007531] cloud-init[137]: ci-info: |   2   | 10.139.121.1 |   0.0.0.0    | 255.255.255.255 |    eth0   |   UH  |
[19849.007585] cloud-init[137]: ci-info: |   3   | 192.168.0.1  | 10.139.121.1 | 255.255.255.255 |    eth0   |  UGH  |
[19849.007625] cloud-init[137]: ci-info: +-------+--------------+--------------+-----------------+-----------+-------+
[19849.007665] cloud-init[137]: ci-info: ++++++++++++++++++++++++++++++++++Route IPv6 info++++++++++++++++++++++++++++++++++
[19849.007713] cloud-init[137]: ci-info: +-------+--------------------------+--------------------------+-----------+-------+
[19849.007748] cloud-init[137]: ci-info: | Route |       Destination        |         Gateway          | Interface | Flags |
[19849.007781] cloud-init[137]: ci-info: +-------+--------------------------+--------------------------+-----------+-------+
[19849.007813] cloud-init[137]: ci-info: |   0   | fd42:9391:4343:38fa::/64 |            ::            |    eth0   |   U   |
[19849.007846] cloud-init[137]: ci-info: |   1   |        fe80::/64         |            ::            |    eth0   |   U   |
[19849.007879] cloud-init[137]: ci-info: |   2   |           ::/0           | fe80::216:3eff:fe5a:a9da |    eth0   |  UGe  |
[19849.007913] cloud-init[137]: ci-info: |   4   |          local           |            ::            |    eth0   |   U   |
[19849.007950] cloud-init[137]: ci-info: |   5   |        multicast         |            ::            |    eth0   |   U   |
[19849.007983] cloud-init[137]: ci-info: +-------+--------------------------+--------------------------+-----------+-------+
````

On the instance itself we configure /etc/nsd/nsd.conf.d/server.conf 

````bash
# Test
dig @127.0.0.1 slainte.at A


nano /etc/nsd/nsd.conf.d/server.conf 


nsd-checkconf /etc/nsd/nsd.conf -v
# Read file /etc/nsd/nsd.conf: 3 patterns, 3 fixed-zones, 0 keys, 0 tls-auth.
# Config settings.
server:
	debug-mode: no
	ip-transparent: no
	ip-freebind: no
	reuseport: no
	do-ip4: yes
	do-ip6: yes
	send-buffer-size: 0
	receive-buffer-size: 0
	hide-version: no
	hide-identity: no
	drop-updates: no
	tcp-reject-overflow: no
	#identity:
	#version:
	#nsid:
	#logfile:
	log-only-syslog: yes
	server-count: 1
	tcp-count: 100
	tcp-query-count: 0
	tcp-timeout: 120
	tcp-mss: 0
	outgoing-tcp-mss: 0
	xfrd-tcp-max: 128
	xfrd-tcp-pipeline: 128
	ipv4-edns-size: 1232
	ipv6-edns-size: 1232
	pidfile: "/run/nsd/nsd.pid"
	port: "53"
	statistics: 0
	#chroot:
	username: "nsd"
	zonesdir: "/etc/nsd"
	xfrdfile: "/var/lib/nsd/xfrd.state"
	zonelistfile: "/var/lib/nsd/zone.list"
	xfrdir: "/tmp"
	xfrd-reload-timeout: 1
	log-time-ascii: yes
	round-robin: no
	minimal-responses: no
	confine-to-zone: no
	refuse-any: no
	verbosity: 0
	ip-address: 10.139.121.5
	rrl-size: 1000000
	rrl-ratelimit: 200
	rrl-slip: 2
	rrl-ipv4-prefix-length: 24
	rrl-ipv6-prefix-length: 64
	rrl-whitelist-ratelimit: 2000
	zonefiles-check: yes
	zonefiles-write: 3600
	#tls-service-key:
	#tls-service-pem:
	#tls-service-ocsp:
	tls-port: "853"
	#tls-cert-bundle:
	answer-cookie: no
	cookie-secret-file: "/etc/nsd/nsd_cookiesecrets.txt"

dnstap:
	dnstap-enable: no
	dnstap-socket-path: "/var/run/nsd-dnstap.sock"
	dnstap-ip: ""
	dnstap-tls: yes
	#dnstap-tls-server-name:
	#dnstap-tls-cert-bundle:
	#dnstap-tls-client-key-file:
	#dnstap-tls-client-cert-file:
	dnstap-send-identity: no
	dnstap-send-version: no
	#dnstap-identity:
	#dnstap-version:
	dnstap-log-auth-query-messages: no
	dnstap-log-auth-response-messages: no

remote-control:
	control-enable: yes
	control-port: 8952
	server-key-file: "/etc/nsd/nsd_server.key"
	server-cert-file: "/etc/nsd/nsd_server.pem"
	control-key-file: "/etc/nsd/nsd_control.key"
	control-cert-file: "/etc/nsd/nsd_control.pem"

verify:
	enable: no
	port: 5347
	verify-zones: yes
	verifier-count: 1
	verifier-feed-zone: yes
	verifier-timeout: 0

zone:
	name: "121.139.10.in-addr.arpa"
	request-xfr: AXFR 10.139.121.1@8853 NOKEY

zone:
	name: "a.f.8.3.3.4.3.4.1.9.3.9.2.4.d.f.ip6.arpa"
	request-xfr: AXFR 10.139.121.1@8853 NOKEY

zone:
	name: "demo.example.net"
	request-xfr: AXFR 10.139.121.1@8853 NOKEY




systemctl restart nsd

nsd-control transfer -v
ok, 3 zones

journalctl -f
Sep 15 16:27:17 ns1 nsd[335]: xfrd: zone lxd.slainte.at received error code REFUSED from 10.139.121.5@8853
Sep 15 16:28:50 ns1 nsd[336]: signal received, shutting down...
Sep 15 16:28:50 ns1 systemd[1]: Stopping nsd.service - Name Server Daemon...
Sep 15 16:28:50 ns1 systemd[1]: nsd.service: Deactivated successfully.
Sep 15 16:28:50 ns1 systemd[1]: Stopped nsd.service - Name Server Daemon.
Sep 15 16:28:50 ns1 systemd[1]: Starting nsd.service - Name Server Daemon...
Sep 15 16:28:50 ns1 nsd[348]: nsd starting (NSD 4.8.0)
Sep 15 16:28:51 ns1 nsd[349]: nsd started (NSD 4.8.0), pid 348
Sep 15 16:28:51 ns1 systemd[1]: Started nsd.service - Name Server Daemon.
Sep 15 16:28:54 ns1 nsd[348]: control cmd:  transfer

nsd-control status
version: 4.8.0
verbosity: 3
ratelimit: 200

nsd-control zonestatus
zone:	121.139.10.in-addr.arpa
	state: refreshing
	served-serial: none
	commit-serial: none
	notified-serial: "0 since 2025-09-15T18:47:31"
	transfer: "TCP connected to 10.139.121.1@8853"
zone:	a.f.8.3.3.4.3.4.1.9.3.9.2.4.d.f.ip6.arpa
	state: refreshing
	served-serial: none
	commit-serial: none
	notified-serial: "0 since 2025-09-15T18:47:31"
	transfer: "TCP connected to 10.139.121.1@8853"
zone:	demo.example.net
	state: refreshing
	served-serial: none
	commit-serial: none
	notified-serial: "0 since 2025-09-15T18:47:31"
	transfer: "TCP connected to 10.139.121.1@8853"




````



## References

- [nsd Setup](https://wiki.alpinelinux.org/wiki/Setting_up_nsd_DNS_server)
- [nsd setup generell](https://ipv6.rs/tutorial/Alpine_Linux_Latest/NSD/)
- [lxd Dokumentation on youtube](https://www.youtube.com/watch?v=2MqpJOogNVQ)


