# http-echo - Test connectivity

## Test test.http-echo-simple.slainte.at

This is a page with simple tls-mode

Test with http. This will lead to **"301 Moved Permanently"**

````bash
alfred@lxd:~$ curl -k -v http://test.http-echo-simple.slainte.at
* Host test.http-echo-simple.slainte.at:80 was resolved.
* IPv6: (none)
* IPv4: 10.242.64.201
*   Trying 10.242.64.201:80...
* Connected to test.http-echo-simple.slainte.at (10.242.64.201) port 80
> GET / HTTP/1.1
> Host: test.http-echo-simple.slainte.at
> User-Agent: curl/8.5.0
> Accept: */*
> 
< HTTP/1.1 301 Moved Permanently
< location: https://test.http-echo-simple.slainte.at/
< date: Mon, 29 Dec 2025 10:45:41 GMT
< server: istio-envoy
< content-length: 0
< 
* Connection #0 to host test.http-echo-simple.slainte.at left intact
alfred@lxd:~$
````

Now test with https. This will suceed.
````bash
alfred@lxd:~$ curl -k -v https://test.http-echo-simple.slainte.at
* Host test.http-echo-simple.slainte.at:443 was resolved.
* IPv6: (none)
* IPv4: 10.242.64.201
*   Trying 10.242.64.201:443...
* Connected to test.http-echo-simple.slainte.at (10.242.64.201) port 443
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
*  subject: O=http-echo-simple-slainte-at; OU=test
*  start date: Dec 29 10:16:38 2025 GMT
*  expire date: Mar 29 10:16:38 2026 GMT
*  issuer: CN=k8s-selfsigned-ca
*  SSL certificate verify result: unable to get local issuer certificate (20), continuing anyway.
*   Certificate level 0: Public key type RSA (2048/112 Bits/secBits), signed using ecdsa-with-SHA256
* using HTTP/2
* [HTTP/2] [1] OPENED stream for https://test.http-echo-simple.slainte.at/
* [HTTP/2] [1] [:method: GET]
* [HTTP/2] [1] [:scheme: https]
* [HTTP/2] [1] [:authority: test.http-echo-simple.slainte.at]
* [HTTP/2] [1] [:path: /]
* [HTTP/2] [1] [user-agent: curl/8.5.0]
* [HTTP/2] [1] [accept: */*]
> GET / HTTP/2
> Host: test.http-echo-simple.slainte.at
> User-Agent: curl/8.5.0
> Accept: */*
> 
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* old SSL session ID is stale, removing
< HTTP/2 200 
< x-app-name: http-echo
< x-app-version: 0.2.3
< date: Mon, 29 Dec 2025 10:46:08 GMT
< content-length: 22
< content-type: text/plain; charset=utf-8
< x-envoy-upstream-service-time: 2
< server: istio-envoy
< 
hello from istio demo
* Connection #0 to host test.http-echo-simple.slainte.at left intact
alfred@lxd:~$ 
````
## Test test.http-echo-mutual.slainte.at

This is a page with mutual tls-mode

Test with http. This will lead to **"301 Moved Permanently"**

````bash
alfred@lxd:~$ curl -k -v http://test.http-echo-mutual.slainte.at
* Host test.http-echo-mutual.slainte.at:80 was resolved.
* IPv6: (none)
* IPv4: 10.242.64.201
*   Trying 10.242.64.201:80...
* Connected to test.http-echo-mutual.slainte.at (10.242.64.201) port 80
> GET / HTTP/1.1
> Host: test.http-echo-mutual.slainte.at
> User-Agent: curl/8.5.0
> Accept: */*
> 
< HTTP/1.1 301 Moved Permanently
< location: https://test.http-echo-mutual.slainte.at/
< date: Mon, 29 Dec 2025 10:48:31 GMT
< server: istio-envoy
< content-length: 0
< 
* Connection #0 to host test.http-echo-mutual.slainte.at left intact
alfred@lxd:~$ 
````
Test with http. This will lead to **"routines::tlsv13 alert certificate required"**

````bash
alfred@lxd:~$ curl -k -v https://test.http-echo-mutual.slainte.at
* Host test.http-echo-mutual.slainte.at:443 was resolved.
* IPv6: (none)
* IPv4: 10.242.64.201
*   Trying 10.242.64.201:443...
* Connected to test.http-echo-mutual.slainte.at (10.242.64.201) port 443
* ALPN: curl offers h2,http/1.1
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Request CERT (13):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Certificate (11):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384 / X25519 / RSASSA-PSS
* ALPN: server accepted h2
* Server certificate:
*  subject: O=http-echo-mutual-slainte-at; OU=test
*  start date: Dec 29 10:16:38 2025 GMT
*  expire date: Mar 29 10:16:38 2026 GMT
*  issuer: CN=k8s-selfsigned-ca
*  SSL certificate verify result: unable to get local issuer certificate (20), continuing anyway.
*   Certificate level 0: Public key type RSA (2048/112 Bits/secBits), signed using ecdsa-with-SHA256
* using HTTP/2
* [HTTP/2] [1] OPENED stream for https://test.http-echo-mutual.slainte.at/
* [HTTP/2] [1] [:method: GET]
* [HTTP/2] [1] [:scheme: https]
* [HTTP/2] [1] [:authority: test.http-echo-mutual.slainte.at]
* [HTTP/2] [1] [:path: /]
* [HTTP/2] [1] [user-agent: curl/8.5.0]
* [HTTP/2] [1] [accept: */*]
> GET / HTTP/2
> Host: test.http-echo-mutual.slainte.at
> User-Agent: curl/8.5.0
> Accept: */*
> 
* TLSv1.3 (IN), TLS alert, unknown (628):
* OpenSSL SSL_read: OpenSSL/3.0.13: error:0A00045C:SSL routines::tlsv13 alert certificate required, errno 0
* Failed receiving HTTP2 data: 56(Failure when receiving data from the peer)
* Connection #0 to host test.http-echo-mutual.slainte.at left intact
curl: (56) OpenSSL SSL_read: OpenSSL/3.0.13: error:0A00045C:SSL routines::tlsv13 alert certificate required, errno 0
alfred@lxd:~$ 
````
Now lets go with the certificate for this connection. This will succeed.

````bash
alfred@lxd:~/Dokumente$ curl -k -v https://test.http-echo-mutual.slainte.at \
> --cert alfred@slainte.at.crt \
> --key alfred@slainte.at.key \
> --cacert k8s-selfsigned-ca-secret.crt 
* Host test.http-echo-mutual.slainte.at:443 was resolved.
* IPv6: (none)
* IPv4: 10.242.64.201
*   Trying 10.242.64.201:443...
* Connected to test.http-echo-mutual.slainte.at (10.242.64.201) port 443
* ALPN: curl offers h2,http/1.1
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Request CERT (13):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Certificate (11):
* TLSv1.3 (OUT), TLS handshake, CERT verify (15):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384 / X25519 / RSASSA-PSS
* ALPN: server accepted h2
* Server certificate:
*  subject: O=http-echo-mutual-slainte-at; OU=test
*  start date: Dec 29 10:16:38 2025 GMT
*  expire date: Mar 29 10:16:38 2026 GMT
*  issuer: CN=k8s-selfsigned-ca
*  SSL certificate verify result: unable to get local issuer certificate (20), continuing anyway.
*   Certificate level 0: Public key type RSA (2048/112 Bits/secBits), signed using ecdsa-with-SHA256
* using HTTP/2
* [HTTP/2] [1] OPENED stream for https://test.http-echo-mutual.slainte.at/
* [HTTP/2] [1] [:method: GET]
* [HTTP/2] [1] [:scheme: https]
* [HTTP/2] [1] [:authority: test.http-echo-mutual.slainte.at]
* [HTTP/2] [1] [:path: /]
* [HTTP/2] [1] [user-agent: curl/8.5.0]
* [HTTP/2] [1] [accept: */*]
> GET / HTTP/2
> Host: test.http-echo-mutual.slainte.at
> User-Agent: curl/8.5.0
> Accept: */*
> 
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* old SSL session ID is stale, removing
< HTTP/2 200 
< x-app-name: http-echo
< x-app-version: 0.2.3
< date: Mon, 29 Dec 2025 10:52:56 GMT
< content-length: 22
< content-type: text/plain; charset=utf-8
< x-envoy-upstream-service-time: 1
< server: istio-envoy
< 
hello from istio demo
* Connection #0 to host test.http-echo-mutual.slainte.at left intact
alfred@lxd:~/Dokumente$
````

This is working.

A valid pk12 certificate is created with the help of https://github.com/Alfred-Sabitzer/microk8s-ubuntu/blob/main/setup/Istio/demo/demo_client_certificate.sh 
