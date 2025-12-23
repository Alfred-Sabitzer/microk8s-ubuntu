# http-echo - Test connectivity

Test with http. This will lead to **"301 Moved Permanently"**

````bash
alfred@lxd:~/cert$ curl -k -v http://test.http-echo.slainte.at
* Host test.http-echo.slainte.at:80 was resolved.
* IPv6: (none)
* IPv4: 10.242.64.201, 10.242.64.201
*   Trying 10.242.64.201:80...
* Connected to test.http-echo.slainte.at (10.242.64.201) port 80
> GET / HTTP/1.1
> Host: test.http-echo.slainte.at
> User-Agent: curl/8.5.0
> Accept: */*
> 
< HTTP/1.1 301 Moved Permanently
< location: https://test.http-echo.slainte.at/
< date: Tue, 23 Dec 2025 09:54:58 GMT
< server: istio-envoy
< content-length: 0
< 
* Connection #0 to host test.http-echo.slainte.at left intact
````

Now test with https. Will lead to **"certificate required"**
````bash
alfred@lxd:~/cert$ curl -k -v https://test.http-echo.slainte.at
* Host test.http-echo.slainte.at:443 was resolved.
* IPv6: (none)
* IPv4: 10.242.64.201, 10.242.64.201
*   Trying 10.242.64.201:443...
* Connected to test.http-echo.slainte.at (10.242.64.201) port 443
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
*  subject: [NONE]
*  start date: Dec 22 12:20:43 2025 GMT
*  expire date: Mar 22 12:20:43 2026 GMT
*   Certificate level 0: Public key type RSA (2048/112 Bits/secBits), signed using sha256WithRSAEncryption
* TLSv1.3 (IN), TLS alert, unknown (628):
* OpenSSL SSL_read: OpenSSL/3.0.13: error:0A00045C:SSL routines::tlsv13 alert certificate required, errno 0
* Failed receiving HTTP2 data: 56(Failure when receiving data from the peer)
* Connection #0 to host test.http-echo.slainte.at left intact
curl: (56) OpenSSL SSL_read: OpenSSL/3.0.13: error:0A00045C:SSL routines::tlsv13 alert certificate required, errno 0
````

Now lets go with the certificate for this connection. This will succeed.

````bash
alfred@lxd:~/cert$ curl -k -vvv --cert wildcard-slainte-at-mtls-credential_ca.crt --key wildcard-slainte-at-mtls-credential_tls.key https://test.http-echo.slainte.at/
* Host test.http-echo.slainte.at:443 was resolved.
* IPv6: (none)
* IPv4: 10.242.64.201, 10.242.64.201
*   Trying 10.242.64.201:443...
* Connected to test.http-echo.slainte.at (10.242.64.201) port 443
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
*  subject: [NONE]
*  start date: Dec 22 12:20:43 2025 GMT
*  expire date: Mar 22 12:20:43 2026 GMT
*   Certificate level 0: Public key type RSA (2048/112 Bits/secBits), signed using sha256WithRSAEncryption
* using HTTP/2
* [HTTP/2] [1] OPENED stream for https://test.http-echo.slainte.at/
* [HTTP/2] [1] [:method: GET]
* [HTTP/2] [1] [:scheme: https]
* [HTTP/2] [1] [:authority: test.http-echo.slainte.at]
* [HTTP/2] [1] [:path: /]
* [HTTP/2] [1] [user-agent: curl/8.5.0]
* [HTTP/2] [1] [accept: */*]
> GET / HTTP/2
> Host: test.http-echo.slainte.at
> User-Agent: curl/8.5.0
> Accept: */*
> 
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* old SSL session ID is stale, removing
< HTTP/2 200 
< x-app-name: http-echo
< x-app-version: 0.2.3
< date: Tue, 23 Dec 2025 17:56:18 GMT
< content-length: 22
< content-type: text/plain; charset=utf-8
< x-envoy-upstream-service-time: 2
< server: istio-envoy
< 
hello from istio demo
* Connection #0 to host test.http-echo.slainte.at left intact
````

