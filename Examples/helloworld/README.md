# Hello World

Das ist ein Testbeispiel für ein Hello-World.

## Vorbereitung

Es muß einen existierenden Cluster geben, und dort muß eine Docker-Registry laufen.

## Skript um zu bauen

Das bauen des Docker-Images muß auf dem Raspberry-PI-Build-Rechner erfolgen.

```
./do.sh
```

Dieses Skript baut das Docker-Image und checkt es in die richtige Registry ein.

## Einspielen des Kubernetes Services

Der Service kann sehr leicht eingespielt werden.

```
$ k apply -f .
horizontalpodautoscaler.autoscaling/hello-world-hpa configured
ingress.networking.k8s.io/hello-world unchanged
poddisruptionbudget.policy/hello-world-pdb configured
service/hello-world-svc unchanged
deployment.apps/hello-world-depl configured
namespace/slainte unchanged

```
Die Kontrolle des Deployments erfolgt dann mit

```
pod/hello-world-depl-95b47ff9d-jc82v   1/1     Running   0          6m33s
pod/hello-world-depl-95b47ff9d-m6b65   1/1     Running   0          6m33s
pod/hello-world-depl-95b47ff9d-pgmbd   1/1     Running   0          6m48s
pod/hello-world-depl-95b47ff9d-qf645   1/1     Running   0          10m
service/hello-world-svc   ClusterIP   10.152.183.183   <none>        80/TCP    11h
deployment.apps/hello-world-depl   4/4     4            4           11h
replicaset.apps/hello-world-depl-54655d478b   0         0         0       11h
replicaset.apps/hello-world-depl-5d59b4ccbf   0         0         0       11h
replicaset.apps/hello-world-depl-95b47ff9d    4         4         4       11h
horizontalpodautoscaler.autoscaling/hello-world-hpa   Deployment/hello-world-depl   memory: 12910592/20Mi   1         10        4          11h
```
Ein Verbindungstest sollte folgendes liefern:

```
curl -k -v https://k8s.slainte.at/
*   Trying 192.168.0.210:443...
* Connected to k8s.slainte.at (192.168.0.210) port 443 (#0)
* ALPN: offers h2
* ALPN: offers http/1.1
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
* ALPN: server accepted h2
* Server certificate:
*  subject: CN=k8s.slainte.at
*  start date: Sep  2 14:08:43 2022 GMT
*  expire date: Dec  1 14:08:42 2022 GMT
*  issuer: C=US; O=Let's Encrypt; CN=R3
*  SSL certificate verify result: unable to get local issuer certificate (20), continuing anyway.
* Using HTTP2, server supports multiplexing
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* h2h3 [:method: GET]
* h2h3 [:path: /]
* h2h3 [:scheme: https]
* h2h3 [:authority: k8s.slainte.at]
* h2h3 [user-agent: curl/7.84.0]
* h2h3 [accept: */*]
* Using Stream ID: 1 (easy handle 0x558b0c8b60c0)
> GET / HTTP/2
> Host: k8s.slainte.at
> user-agent: curl/7.84.0
> accept: */*
> 
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* old SSL session ID is stale, removing
* Connection state changed (MAX_CONCURRENT_STREAMS == 128)!
< HTTP/2 200 
< date: Fri, 02 Sep 2022 15:40:47 GMT
< content-type: text/html; charset=utf-8
< strict-transport-security: max-age=15724800; includeSubDomains
< 
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"><html><head>	<meta http-equiv="content-type" content="text/html; charset=utf-8"/>	<title></title>	<meta name="generator" content="LibreOffice 7.1.6.2 (Linux)"/>	<meta name="author" content="Alfred Sabitzer"/>	<meta name="created" content="2021-10-07T16:33:50.696105947"/>	<meta name="changedby" content="Alfred Sabitzer"/>	<meta name="changed" content="2021-10-07T16:36:08.816466992"/>	<style type="text/css">		@page { size: 21cm 29.7cm; margin: 2cm }		p { margin-bottom: 0.25cm; line-height: 115%; background: transparent }		td p { orphans: 0; widows: 0; background: transparent }	</style></head><body lang="de-AT" link="#000080" vlink="#800000" dir="ltr"><p style="margin-bottom: 0cm; line-height: 100%"><p style="margin-bottom: 0cm; line-height: 100%"><br/></p><table width="100%" cellpadding="4" cellspacing="0">	<col width="64*"/>	<col width="64*"/>	<col width="64*"/>	<col width="64*"/>	<tr valign="top">		<td width="25%" style="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: none; padding-top: 0.1cm; padding-bottom: 0.1cm; padding-left: 0.1cm; padding-right: 0cm"><p>			OSENVIRONMENT</p>		</td><td width="25%" style="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: none; padding-top: 0.1cm; padding-bottom: 0.1cm; padding-left: 0.1cm; padding-right: 0cm"><p>			DISKUSAGE</p>		</td>		<td width="25%" style="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: none; padding-top: 0.1cm; padding-bottom: 0.1cm; padding-left: 0.1cm; padding-right: 0cm"><p>			HOSTINFO</p>		</td>		<td width="25%" style="border: 1px solid #000000; padding: 0.1cm"><p>			MEMINFO</p>	</td>	</tr>	<tr valign="top">		<td width="25%" style="border-top: none; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: none; padding-top: 0cm; padding-bottom: 0.1cm; padding-left: 0.1cm; padding-right: 0cm"><p>		PATH=>/go/bin:/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin<br>HOSTNAME=>hello-world-depl-7cb48686b-lrk6x<br>GOLANG_VERSION=>1.16.15<br>GOPATH=>/go<br>image=>hello-world<br>tag=>latest<br>KUBERNETES_SERVICE_PORT=>443<br>KUBERNETES_SERVICE_PORT_HTTPS=>443<br>KUBERNETES_PORT_443_TCP_PORT=>443<br>HELLO_WORLD_SVC_PORT_80_TCP_PORT=>80<br>KUBERNETES_SERVICE_HOST=>10.152.183.1<br>HELLO_WORLD_SVC_SERVICE_PORT=>80<br>HELLO_WORLD_SVC_PORT_80_TCP=>tcp://10.152.183.196:80<br>HELLO_WORLD_SVC_PORT_80_TCP_PROTO=>tcp<br>KUBERNETES_PORT=>tcp://10.152.183.1:443<br>KUBERNETES_PORT_443_TCP=>tcp://10.152.183.1:443<br>KUBERNETES_PORT_443_TCP_ADDR=>10.152.183.1<br>HELLO_WORLD_SVC_SERVICE_PORT_HELLO_WORLD=>80<br>HELLO_WORLD_SVC_PORT=>tcp://10.152.183.196:80<br>HELLO_WORLD_SVC_PORT_80_TCP_ADDR=>10.152.183.196<br>KUBERNETES_PORT_443_TCP_PROTO=>tcp<br>HELLO_WORLD_SVC_SERVICE_HOST=>10.152.183.196<br>HOME=>/root<br>      </p>		</td>		<td width="25%" style="border-top: none; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: none; padding-top: 0cm; padding-bottom: 0.1cm; padding-left: 0.1cm; padding-right: 0cm"><p>			Pfad:/<br>FSTYPE:<br>Total disk space: 58.2 GB<br>Free disk space: 42.3 GB<br>Used disk space: 13.5 GB<br>Used GB Prozent:24.2<br>Used Inodes:320360<br>Used Inodes Prozent:8.5			</p>		</td>		<td width="25%" style="border-top: none; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: none; padding-top: 0cm; padding-bottom: 0.1cm; padding-left: 0.1cm; padding-right: 0cm"><p>			Hostname: hello-world-depl-7cb48686b-lrk6x<br>OS: linux<br>Platform: alpine<br>Host ID(uuid): 41c32620-9b35-4c8e-b074-9769b0a41aec<br>Uptime (sec): 39381<br>Number of processes running: 1</p>		</td><td width="25%" style="border-top: none; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000; padding-top: 0cm; padding-bottom: 0.1cm; padding-left: 0.1cm; padding-right: 0.1cm"><p>			OS : linux<br>Total memory:  * Connection #0 to host k8s.slainte.at left intact
 7.6 GB<br>Free memory:   0.9 GB<br>Used memory:   3.8 GB<br>Percentage used memory: 50.30</p>		</td>	</tr>	</table><p style="margin-bottom: 0cm; line-height: 100%"><br/></p><p style="margin-bottom: 0cm; line-height: 100%">Es ist <span style="background: #c0c0c0"><sdfield type=DATETIME sdval="44476,6908896088" sdnum="3079;3079;T. MMMM JJJJ">2022-09-02 17:40:47 Friday</sdfield></span></p></body></html>
```

Somit funktioniert alles!

## Testen des Web Servers

Mittels Apapche Toolkit kann Last am Webserver generiert werden.

```
alfred@bureau:~$ ab -n 100000 -c 1000 https://k8s.slainte.at/
This is ApacheBench, Version 2.3 <$Revision: 1903618 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking k8s.slainte.at (be patient)
Completed 10000 requests
Completed 20000 requests
Completed 30000 requests
Completed 40000 requests
Completed 50000 requests
Completed 60000 requests
Completed 70000 requests
Completed 80000 requests
Completed 90000 requests
Completed 100000 requests
Finished 100000 requests


Server Software:        
Server Hostname:        k8s.slainte.at
Server Port:            443
SSL/TLS Protocol:       TLSv1.3,TLS_AES_256_GCM_SHA384,2048,256
Server Temp Key:        X25519 253 bits
TLS Server Name:        k8s.slainte.at

Document Path:          /
Document Length:        4427 bytes

Concurrency Level:      1000
Time taken for tests:   453.964 seconds
Complete requests:      100000
Failed requests:        0
Total transferred:      484200000 bytes
HTML transferred:       442700000 bytes
Requests per second:    220.28 [#/sec] (mean)
Time per request:       4539.642 [ms] (mean)
Time per request:       4.540 [ms] (mean, across all concurrent requests)
Transfer rate:          1041.61 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        5 1863 626.2   1873    4175
Processing:     3 2631 911.8   2643    7362
Waiting:        3 2630 911.8   2642    7362
Total:          8 4493 1446.9   4527   10477

Percentage of the requests served within a certain time (ms)
  50%   4527
  66%   5103
  75%   5474
  80%   5705
  90%   6310
  95%   6802
  98%   7351
  99%   7744
 100%  10477 (longest request)
alfred@bureau:~$ 
```

Das Verhalten des Horizontal Pod Autoscalers kann leicht kontrolliert werden.

```
$ kubectl get hpa -n slainte hello-world-hpa --watch

hello-world-hpa   Deployment/hello-world-depl   memory: 19509248/20Mi       1         10        1          10h
hello-world-hpa   Deployment/hello-world-depl   memory: 19693568/20Mi       1         10        4          10h
hello-world-hpa   Deployment/hello-world-depl   memory: 18709162666m/20Mi   1         10        6          10h
hello-world-hpa   Deployment/hello-world-depl   memory: 17228595200m/20Mi   1         10        6          10h
hello-world-hpa   Deployment/hello-world-depl   memory: 16605866666m/20Mi   1         10        6          10h
hello-world-hpa   Deployment/hello-world-depl   memory: 16260437333m/20Mi   1         10        6          10h
hello-world-hpa   Deployment/hello-world-depl   memory: 13078528/20Mi       1         10        6          10h
hello-world-hpa   Deployment/hello-world-depl   memory: 12315989333m/20Mi   1         10        6          10h
hello-world-hpa   Deployment/hello-world-depl   memory: 12256597333m/20Mi   1         10        6          10h
hello-world-hpa   Deployment/hello-world-depl   memory: 12898304/20Mi       1         10        6          11h
hello-world-hpa   Deployment/hello-world-depl   memory: 12698965333m/20Mi   1         10        6          11h
hello-world-hpa   Deployment/hello-world-depl   memory: 12561066666m/20Mi   1         10        6          11h
hello-world-hpa   Deployment/hello-world-depl   memory: 12050432/20Mi       1         10        6          11h
hello-world-hpa   Deployment/hello-world-depl   memory: 11947349333m/20Mi   1         10        6          11h
hello-world-hpa   Deployment/hello-world-depl   memory: 11955541333m/20Mi   1         10        6          11h
hello-world-hpa   Deployment/hello-world-depl   memory: 12354901333m/20Mi   1         10        6          11h

```
Der Service skaliert Last-Abhängig und ist auch recht robust.
