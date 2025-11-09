# http-echo - Test connectivity

Test with http.

```bash
alfred@lxd:~$ curl -k -v http://http.slainte.at
* Host http.slainte.at:80 was resolved.
* IPv6: (none)
* IPv4: 192.168.0.211
*   Trying 192.168.0.211:80...
* Connected to http.slainte.at (192.168.0.211) port 80
> GET / HTTP/1.1
> Host: http.slainte.at
> User-Agent: curl/8.5.0
> Accept: */*
> 
< HTTP/1.1 301 Moved Permanently
< location: https://http.slainte.at/
< date: Sun, 09 Nov 2025 09:52:47 GMT
< server: istio-envoy
< content-length: 0
< 
* Connection #0 to host http.slainte.at left intact
```

And now test with https.

```bash
alfred@lxd:~$ curl -k -v https://http.slainte.at
* Host http.slainte.at:443 was resolved.
* IPv6: (none)
* IPv4: 192.168.0.211
*   Trying 192.168.0.211:443...
* Connected to http.slainte.at (192.168.0.211) port 443
* ALPN: curl offers h2,http/1.1
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384 / X25519 / RSASSA-PSS
* ALPN: server accepted h2
* Server certificate:
*  subject: [NONE]
*  start date: Oct 31 19:58:39 2025 GMT
*  expire date: Jan 29 19:58:39 2026 GMT
*   Certificate level 0: Public key type RSA (2048/112 Bits/secBits), signed using sha256WithRSAEncryption
* using HTTP/2
* [HTTP/2] [1] OPENED stream for https://http.slainte.at/
* [HTTP/2] [1] [:method: GET]
* [HTTP/2] [1] [:scheme: https]
* [HTTP/2] [1] [:authority: http.slainte.at]
* [HTTP/2] [1] [:path: /]
* [HTTP/2] [1] [user-agent: curl/8.5.0]
* [HTTP/2] [1] [accept: */*]
> GET / HTTP/2
> Host: http.slainte.at
> User-Agent: curl/8.5.0
> Accept: */*
> 
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* old SSL session ID is stale, removing
< HTTP/2 200 
< x-app-name: http-echo
< x-app-version: 0.2.3
< date: Sun, 09 Nov 2025 09:52:53 GMT
< content-length: 22
< content-type: text/plain; charset=utf-8
< x-envoy-upstream-service-time: 16
< server: istio-envoy
< 
hello from istio demo
* Connection #0 to host http.slainte.at left intact
alfred@lxd:~$ 
```
