#!/bin/bash
############################################################################################
#
# Connect to harbor
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
shopt -o -s xtrace #—Displays each command before it is executed.
shopt -o -s nounset #-No Variables without definition

# Test with public repo
curl --cert ~/pki/alfred-slainte-at/tls.crt \
 --key ~/pki/alfred-slainte-at/tls.key \
 --cacert ~/pki/alfred-slainte-at/ca.crt  \
 -X GET  https://harbor.test.slainte.at/api/v2.0/search?q=library -H 'accept: application/json'
#
#{"project":[{"creation_time":"2026-07-30T06:45:14.113Z","current_user_role_ids":null,"cve_allowlist":{"creation_time":"0001-01-01T00:00:00.000Z","items":null,"update_time":"0001-01-01T00:00:00.000Z"},"metadata":{"public":"true"},"name":"library","owner_id":1,"project_id":1,"repo_count":0,"update_time":"2026-07-30T06:45:14.113Z"}],"repository":[]}
#

# Test with central keys
curl --cert /etc/containers/certs.d/harbor.test.slainte.at/client.cert \
 --key /etc/containers/certs.d/harbor.test.slainte.at/client.key \
 --cacert /etc/containers/certs.d/harbor.test.slainte.at/ca.crt  \
 -X GET  https://harbor.test.slainte.at/api/v2.0/search?q=library -H 'accept: application/json'
#
# {"project":[{"creation_time":"2026-07-30T06:45:14.113Z","current_user_role_ids":null,"cve_allowlist":{"creation_time":"0001-01-01T00:00:00.000Z","items":null,"update_time":"0001-01-01T00:00:00.000Z"},"metadata":{"public":"true"},"name":"library","owner_id":1,"project_id":1,"repo_count":0,"update_time":"2026-07-30T06:45:14.113Z"}],"repository":[]}
#

# test against official url
curl --cert /etc/containers/certs.d/harbor.test.slainte.at/client.cert \
 --key /etc/containers/certs.d/harbor.test.slainte.at/client.key \
 --cacert /etc/containers/certs.d/harbor.test.slainte.at/ca.crt  \
 -v https://harbor.test.slainte.at
#
# * Host harbor.test.slainte.at:443 was resolved.
# * IPv6: (none)
# * IPv4: 10.242.64.201
# *   Trying 10.242.64.201:443...
# * Connected to harbor.test.slainte.at (10.242.64.201) port 443
# * ALPN: curl offers h2,http/1.1
# * TLSv1.3 (OUT), TLS handshake, Client hello (1):
# *  CAfile: /etc/containers/certs.d/harbor.test.slainte.at/ca.crt
# *  CApath: /etc/ssl/certs
# * TLSv1.3 (IN), TLS handshake, Server hello (2):
# * TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
# * TLSv1.3 (IN), TLS handshake, Request CERT (13):
# * TLSv1.3 (IN), TLS handshake, Certificate (11):
# * TLSv1.3 (IN), TLS handshake, CERT verify (15):
# * TLSv1.3 (IN), TLS handshake, Finished (20):
# * TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
# * TLSv1.3 (OUT), TLS handshake, Certificate (11):
# * TLSv1.3 (OUT), TLS handshake, CERT verify (15):
# * TLSv1.3 (OUT), TLS handshake, Finished (20):
# * SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384 / X25519 / id-ecPublicKey
# * ALPN: server accepted h2
# * Server certificate:
# *  subject: C=AT; ST=Vienna; O=Slainte Organization; OU=*.test.slainte.at
# *  start date: Aug  4 16:01:52 2026 GMT
# *  expire date: Nov  2 16:01:52 2026 GMT
# *  subjectAltName: host "harbor.test.slainte.at" matched cert's "*.test.slainte.at"
# *  issuer: CN=k8s-root-ca
# *  SSL certificate verify ok.
# *   Certificate level 0: Public key type EC/prime256v1 (256/128 Bits/secBits), signed using ecdsa-with-SHA256
# *   Certificate level 1: Public key type EC/prime256v1 (256/128 Bits/secBits), signed using ecdsa-with-SHA256
# * using HTTP/2
# * [HTTP/2] [1] OPENED stream for https://harbor.test.slainte.at/
# * [HTTP/2] [1] [:method: GET]
# * [HTTP/2] [1] [:scheme: https]
# * [HTTP/2] [1] [:authority: harbor.test.slainte.at]
# * [HTTP/2] [1] [:path: /]
# * [HTTP/2] [1] [user-agent: curl/8.5.0]
# * [HTTP/2] [1] [accept: */*]
# > GET / HTTP/2
# > Host: harbor.test.slainte.at
# > User-Agent: curl/8.5.0
# > Accept: */*
# > 
# * TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
# * TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
# * old SSL session ID is stale, removing
# < HTTP/2 200 
# < server: istio-envoy
# < date: Sun, 09 Aug 2026 13:32:29 GMT
# < content-type: text/html
# < content-length: 785
# < last-modified: Wed, 06 May 2026 02:08:14 GMT
# < etag: "69faa28e-311"
# < cache-control: no-store, no-cache, must-revalidate
# < accept-ranges: bytes
# < x-frame-options: DENY
# < content-security-policy: frame-ancestors 'none'
# < x-envoy-upstream-service-time: 0
# < 
# <!DOCTYPE html>
# <html>
#     <head>
#         <meta charset="utf-8"/>
#         <title>Harbor</title>
#         <base href="/"/>
#         <meta name="viewport" content="width=device-width, initial-scale=1"/>
#         <link rel="icon" type="image/x-icon" href="favicon.ico?v=2"/>
#     <link rel="stylesheet" href="styles.ac415221c96d2bef.css"></head>
#     <body>
#         <harbor-app>
#             <div class="spinner spinner-lg app-loading app-loading-fixed">
#                 Loading...
#             </div>
#         </harbor-app>
#     <script src="runtime.4899d6f1bff1cddd.js" type="module"></script><script src="polyfills.d87db3092ff69ed9.js" type="module"></script><script src="scripts.3846d86d42cdb753.js" defer></script><script src="main.b8d1f0e63dd036eb.js" type="module"></script></body>
# </html>
# * Connection #0 to host harbor.test.slainte.at left intact



# Test against API
curl --cert /etc/containers/certs.d/harbor.test.slainte.at/client.cert \
 --key /etc/containers/certs.d/harbor.test.slainte.at/client.key \
 --cacert /etc/containers/certs.d/harbor.test.slainte.at/ca.crt  \
 -v https://harbor.test.slainte.at/v2/

# * Host harbor.test.slainte.at:443 was resolved.
# * IPv6: (none)
# * IPv4: 10.242.64.201
# *   Trying 10.242.64.201:443...
# * Connected to harbor.test.slainte.at (10.242.64.201) port 443
# * ALPN: curl offers h2,http/1.1
# * TLSv1.3 (OUT), TLS handshake, Client hello (1):
# *  CAfile: /etc/containers/certs.d/harbor.test.slainte.at/ca.crt
# *  CApath: /etc/ssl/certs
# * TLSv1.3 (IN), TLS handshake, Server hello (2):
# * TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
# * TLSv1.3 (IN), TLS handshake, Request CERT (13):
# * TLSv1.3 (IN), TLS handshake, Certificate (11):
# * TLSv1.3 (IN), TLS handshake, CERT verify (15):
# * TLSv1.3 (IN), TLS handshake, Finished (20):
# * TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
# * TLSv1.3 (OUT), TLS handshake, Certificate (11):
# * TLSv1.3 (OUT), TLS handshake, CERT verify (15):
# * TLSv1.3 (OUT), TLS handshake, Finished (20):
# * SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384 / X25519 / id-ecPublicKey
# * ALPN: server accepted h2
# * Server certificate:
# *  subject: C=AT; ST=Vienna; O=Slainte Organization; OU=*.test.slainte.at
# *  start date: Aug  4 16:01:52 2026 GMT
# *  expire date: Nov  2 16:01:52 2026 GMT
# *  subjectAltName: host "harbor.test.slainte.at" matched cert's "*.test.slainte.at"
# *  issuer: CN=k8s-root-ca
# *  SSL certificate verify ok.
# *   Certificate level 0: Public key type EC/prime256v1 (256/128 Bits/secBits), signed using ecdsa-with-SHA256
# *   Certificate level 1: Public key type EC/prime256v1 (256/128 Bits/secBits), signed using ecdsa-with-SHA256
# * using HTTP/2
# * [HTTP/2] [1] OPENED stream for https://harbor.test.slainte.at/v2/
# * [HTTP/2] [1] [:method: GET]
# * [HTTP/2] [1] [:scheme: https]
# * [HTTP/2] [1] [:authority: harbor.test.slainte.at]
# * [HTTP/2] [1] [:path: /v2/]
# * [HTTP/2] [1] [user-agent: curl/8.5.0]
# * [HTTP/2] [1] [accept: */*]
# > GET /v2/ HTTP/2
# > Host: harbor.test.slainte.at
# > User-Agent: curl/8.5.0
# > Accept: */*
# > 
# * TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
# * TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
# * old SSL session ID is stale, removing
# < HTTP/2 401 
# < server: istio-envoy
# < date: Sun, 09 Aug 2026 13:33:32 GMT
# < content-type: application/json; charset=utf-8
# < content-length: 76
# < docker-distribution-api-version: registry/2.0
# < set-cookie: sid=e5a6f820ee9ed8cb5b231970945fa3a5; Path=/; HttpOnly
# < www-authenticate: Bearer realm="https://harbor.test.slainte.at/service/token",service="harbor-registry"
# < x-request-id: c8bef348-0a7e-4d9f-9dda-4dddaba0f8e6
# < x-envoy-upstream-service-time: 11
# < 
# {"errors":[{"code":"UNAUTHORIZED","message":"unauthorized: unauthorized"}]}
# * Connection #0 to host harbor.test.slainte.at left intact

# Test against API with admin and password

USER=admin
PASSWORD=${HARBOR_ADMIN_PASSWORD}
curl --cert /etc/containers/certs.d/harbor.test.slainte.at/client.cert \
 --key /etc/containers/certs.d/harbor.test.slainte.at/client.key \
 --cacert /etc/containers/certs.d/harbor.test.slainte.at/ca.crt  \
 -v -u ${USER}:${PASSWORD} https://harbor.test.slainte.at/v2/

# * Host harbor.test.slainte.at:443 was resolved.
# * IPv6: (none)
# * IPv4: 10.242.64.201
# *   Trying 10.242.64.201:443...
# * Connected to harbor.test.slainte.at (10.242.64.201) port 443
# * ALPN: curl offers h2,http/1.1
# * TLSv1.3 (OUT), TLS handshake, Client hello (1):
# *  CAfile: /etc/containers/certs.d/harbor.test.slainte.at/ca.crt
# *  CApath: /etc/ssl/certs
# * TLSv1.3 (IN), TLS handshake, Server hello (2):
# * TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
# * TLSv1.3 (IN), TLS handshake, Request CERT (13):
# * TLSv1.3 (IN), TLS handshake, Certificate (11):
# * TLSv1.3 (IN), TLS handshake, CERT verify (15):
# * TLSv1.3 (IN), TLS handshake, Finished (20):
# * TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
# * TLSv1.3 (OUT), TLS handshake, Certificate (11):
# * TLSv1.3 (OUT), TLS handshake, CERT verify (15):
# * TLSv1.3 (OUT), TLS handshake, Finished (20):
# * SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384 / X25519 / id-ecPublicKey
# * ALPN: server accepted h2
# * Server certificate:
# *  subject: C=AT; ST=Vienna; O=Slainte Organization; OU=*.test.slainte.at
# *  start date: Aug  4 16:01:52 2026 GMT
# *  expire date: Nov  2 16:01:52 2026 GMT
# *  subjectAltName: host "harbor.test.slainte.at" matched cert's "*.test.slainte.at"
# *  issuer: CN=k8s-root-ca
# *  SSL certificate verify ok.
# *   Certificate level 0: Public key type EC/prime256v1 (256/128 Bits/secBits), signed using ecdsa-with-SHA256
# *   Certificate level 1: Public key type EC/prime256v1 (256/128 Bits/secBits), signed using ecdsa-with-SHA256
# * using HTTP/2
# * Server auth using Basic with user 'admin'
# * [HTTP/2] [1] OPENED stream for https://harbor.test.slainte.at/v2/
# * [HTTP/2] [1] [:method: GET]
# * [HTTP/2] [1] [:scheme: https]
# * [HTTP/2] [1] [:authority: harbor.test.slainte.at]
# * [HTTP/2] [1] [:path: /v2/]
# * [HTTP/2] [1] [authorization: Basic YWRtaW46NE51Q04yejJGamhoN1VlYWpYYUY=]
# * [HTTP/2] [1] [user-agent: curl/8.5.0]
# * [HTTP/2] [1] [accept: */*]
# > GET /v2/ HTTP/2
# > Host: harbor.test.slainte.at
# > Authorization: Basic YWRtaW46NE51Q04yejJGamhoN1VlYWpYYUY=
# > User-Agent: curl/8.5.0
# > Accept: */*
# > 
# * TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
# * TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
# * old SSL session ID is stale, removing
# < HTTP/2 400 
# < server: istio-envoy
# < date: Sun, 09 Aug 2026 15:54:28 GMT
# < content-length: 0
# < docker-distribution-api-version: registry/2.0
# < set-cookie: sid=f5ef305b104032fea5600ff6f289fc95; Path=/; HttpOnly
# < x-request-id: 27d40296-d8e4-4543-b803-69610a08dcb4
# < x-envoy-upstream-service-time: 48
# < 
# * Connection #0 to host harbor.test.slainte.at left intact

# let's test the token endpoint with the admin user
# See https://goharbor.io/docs/2.9.0/install-config/configure-system-settings-cli/
#

USER=admin
PASSWORD=${HARBOR_ADMIN_PASSWORD}
curl --cert /etc/containers/certs.d/harbor.test.slainte.at/client.cert \
 --key /etc/containers/certs.d/harbor.test.slainte.at/client.key \
 --cacert /etc/containers/certs.d/harbor.test.slainte.at/ca.crt  \
 -u "${USER}:${PASSWORD}" -H "Content-Type: application/json" -ki https://harbor.test.slainte.at/api/v2.0/configurations
# HTTP/2 200 
# server: istio-envoy
# date: Sun, 09 Aug 2026 15:59:13 GMT
# content-type: application/json
# set-cookie: sid=794aa0cb925afb90cec4a35c4e69f739; Path=/; HttpOnly
# x-request-id: d969626c-d0a2-4a71-b31f-9bcf1e727ce3
# x-frame-options: DENY
# content-security-policy: frame-ancestors 'none'
# x-envoy-upstream-service-time: 18

# {"audit_log_forward_endpoint":{"editable":true,"value":""},"auth_mode":{"editable":false,"value":"db_auth"},"banner_message":{"editable":true,"value":""},"disabled_audit_log_event_types":{"editable":true,"value":""},"http_authproxy_admin_groups":{"editable":true,"value":""},"http_authproxy_admin_usernames":{"editable":true,"value":""},"http_authproxy_endpoint":{"editable":true,"value":""},"http_authproxy_server_certificate":{"editable":true,"value":""},"http_authproxy_skip_search":{"editable":true,"value":false},"http_authproxy_tokenreview_endpoint":{"editable":true,"value":""},"http_authproxy_verify_cert":{"editable":true,"value":true},"ldap_base_dn":{"editable":true,"value":""},"ldap_filter":{"editable":true,"value":""},"ldap_group_admin_dn":{"editable":true,"value":""},"ldap_group_attach_parallel":{"editable":true,"value":false},"ldap_group_attribute_name":{"editable":true,"value":""},"ldap_group_base_dn":{"editable":true,"value":""},"ldap_group_membership_attribute":{"editable":true,"value":"memberof"},"ldap_group_search_filter":{"editable":true,"value":""},"ldap_group_search_scope":{"editable":true,"value":2},"ldap_scope":{"editable":true,"value":2},"ldap_search_dn":{"editable":true,"value":""},"ldap_timeout":{"editable":true,"value":5},"ldap_uid":{"editable":true,"value":"cn"},"ldap_url":{"editable":true,"value":""},"ldap_verify_cert":{"editable":true,"value":true},"notification_enable":{"editable":true,"value":true},"oidc_admin_group":{"editable":true,"value":""},"oidc_auto_onboard":{"editable":true,"value":false},"oidc_client_id":{"editable":true,"value":""},"oidc_endpoint":{"editable":true,"value":""},"oidc_extra_redirect_parms":{"editable":true,"value":"{}"},"oidc_group_filter":{"editable":true,"value":""},"oidc_groups_claim":{"editable":true,"value":""},"oidc_logout":{"editable":true,"value":false},"oidc_name":{"editable":true,"value":""},"oidc_scope":{"editable":true,"value":""},"oidc_user_claim":{"editable":true,"value":""},"oidc_verify_cert":{"editable":true,"value":true},"primary_auth_mode":{"editable":true,"value":false},"project_creation_restriction":{"editable":true,"value":"everyone"},"quota_per_project_enable":{"editable":true,"value":true},"read_only":{"editable":true,"value":false},"robot_name_prefix":{"editable":true,"value":"robot$"},"robot_token_duration":{"editable":true,"value":30},"scan_all_policy":{},"scanner_skip_update_pulltime":{"editable":true,"value":false},"self_registration":{"editable":true,"value":false},"session_timeout":{"editable":true,"value":60},"skip_audit_log_database":{"editable":true,"value":false},"storage_per_project":{"editable":true,"value":-1},"token_expiration":{"editable":true,"value":30},"uaa_client_id":{"editable":true,"value":""},"uaa_client_secret":{"editable":true,"value":""},"uaa_endpoint":{"editable":true,"value":""},"uaa_verify_cert":{"editable":true,"value":false}}

# Test the saame with a non-admin user
USER=alfred
PASSWORD=${HARBOR_PASSWORD}
curl --cert /etc/containers/certs.d/harbor.test.slainte.at/client.cert \
 --key /etc/containers/certs.d/harbor.test.slainte.at/client.key \
 --cacert /etc/containers/certs.d/harbor.test.slainte.at/ca.crt  \
 -u "${USER}:${PASSWORD}" -H "Content-Type: application/json" -ki https://harbor.test.slainte.at/api/v2.0/configurations
# HTTP/2 401 
# server: istio-envoy
# date: Sun, 09 Aug 2026 16:00:25 GMT
# content-type: application/json; charset=utf-8
# content-length: 62
# set-cookie: sid=c579383822e7e7852ec2ad9f6d378da4; Path=/; HttpOnly
# x-request-id: 409faf32-8131-4c4e-b331-a62a4482eeb7
# x-envoy-upstream-service-time: 1521

# {"errors":[{"code":"UNAUTHORIZED","message":"unauthorized"}]}

curl --cert /etc/containers/certs.d/harbor.test.slainte.at/client.cert \
 --key /etc/containers/certs.d/harbor.test.slainte.at/client.key \
 --cacert /etc/containers/certs.d/harbor.test.slainte.at/ca.crt  \
 -u "${USER}:${PASSWORD}" \
 -ki "https://harbor.test.slainte.at/service/token?service=harbor-registry&scope=registry:catalog:*"
# HTTP/2 200 
# server: istio-envoy
# date: Sun, 09 Aug 2026 16:05:10 GMT
# content-type: application/json; charset=utf-8
# content-length: 808
# set-cookie: sid=346fec5ea1e17aa4292c0798c589538e; Path=/; HttpOnly
# x-request-id: 0cfa5e00-0d6c-42bc-90ee-12f3144da845
# x-frame-options: DENY
# content-security-policy: frame-ancestors 'none'
# x-envoy-upstream-service-time: 1541

# {"token":"eyJhbGciOiJSUzI1NiIsImtpZCI6IjVHUUc6SjVMRDpESUo1Okc2VEE6SEk3WjpURFFFOjZZN1o6V1NVUzpMNE5HOjRKRko6TlNNVTpMRDJYIiwidHlwIjoiSldUIn0.eyJpc3MiOiJoYXJib3ItdG9rZW4taXNzdWVyIiwiYXVkIjoiaGFyYm9yLXJlZ2lzdHJ5IiwiZXhwIjoxNzg2MjkzMzEwLCJuYmYiOjE3ODYyOTE1MTAsImlhdCI6MTc4NjI5MTUxMCwianRpIjoiZXRHVjd1UG9sdmNld21KViIsImFjY2VzcyI6W3sidHlwZSI6InJlZ2lzdHJ5IiwibmFtZSI6ImNhdGFsb2ciLCJhY3Rpb25zIjpbXX1dfQ.fIjdNusIZLEuhpcrZgY4dd-jPsf7hMfQXR_aMS2x1_g41Y1JzXC40OLXXfTepXYP5XcHuwp3SqZhHOmZDSeLbU7CHrH75WUFbYBxv3v0b3Ddw6xpOens6UhiQMqWVm8I2W9h3b8_Q2dIeVP0rxAPiLLSG3tvAU4nt9PrkJJLuto-a7mlJCukp7DyPwWaP4LfIJpyvmd5oS6a6Nprtk7psn35s7u60Tb89Cn4bzzUBYtQueCideoqtAdni2G_5y4tx7z45gR7dt8UNJaDPxIDv2JNSgjILP9iY4paodT7I_U2E2chZWIaSb6HW81m9ZwKIzQNiZTmjVGGRLnkt2V7Jg","access_token":"","expires_in":1800,"issued_at":"2026-08-09T16:05:10Z"}
#
TOKEN=$(curl --cert /etc/containers/certs.d/harbor.test.slainte.at/client.cert \
 --key /etc/containers/certs.d/harbor.test.slainte.at/client.key \
 --cacert /etc/containers/certs.d/harbor.test.slainte.at/ca.crt  \
 -u "${USER}:${PASSWORD}" \
 "https://harbor.test.slainte.at/service/token?service=harbor-registry&scope=registry:catalog:*" | cut -d. -f2)
echo "$TOKEN"
curl --cert /etc/containers/certs.d/harbor.test.slainte.at/client.cert \
 --key /etc/containers/certs.d/harbor.test.slainte.at/client.key \
 --cacert /etc/containers/certs.d/harbor.test.slainte.at/ca.crt  \
 -u "${USER}:${PASSWORD}" \
 -H "Authorization: Bearer $TOKEN" \
 "https://harbor.test.slainte.at/v2/_catalog"
#{"errors":[{"code":"UNAUTHORIZED","message":"unauthorized to list catalog: unauthorized to list catalog"}]}

# Test with admin
USER=admin
PASSWORD=${HARBOR_ADMIN_PASSWORD}
TOKEN=$(curl --cert /etc/containers/certs.d/harbor.test.slainte.at/client.cert \
 --key /etc/containers/certs.d/harbor.test.slainte.at/client.key \
 --cacert /etc/containers/certs.d/harbor.test.slainte.at/ca.crt  \
 -u "${USER}:${PASSWORD}" \
 "https://harbor.test.slainte.at/service/token?service=harbor-registry&scope=registry:catalog:*" | cut -d. -f2)
echo "$TOKEN"
curl --cert /etc/containers/certs.d/harbor.test.slainte.at/client.cert \
 --key /etc/containers/certs.d/harbor.test.slainte.at/client.key \
 --cacert /etc/containers/certs.d/harbor.test.slainte.at/ca.crt  \
 -u "${USER}:${PASSWORD}" \
 -H "Authorization: Bearer $TOKEN" \
 "https://harbor.test.slainte.at/v2/_catalog"
# {"errors":[{"code":"UNAUTHORIZED","message":"unauthorized to list catalog: unauthorized to list catalog"}]}
