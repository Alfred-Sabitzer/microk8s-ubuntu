#!/bin/bash
############################################################################################
#
# Install and configure stunnel https://www.stunnel.org/
#
############################################################################################
set -euo pipefail
#shopt -o -s xtrace #—Displays each command before it is executed.

# install stunnel
sudo apt-get install stunnel4 -y

sudo openssl req -x509 -newkey rsa:2048\
    -keyout /etc/containers/certs.d/harbor.test.slainte.at/local.key\
    -out /etc/containers/certs.d/harbor.test.slainte.at/local.crt\
    -days 365\
    -nodes -subj "/CN=localhost"

cat << EOF | sudo tee /etc/stunnel/harbor-registry.conf
client = yes
[harbor-mTLS-tunnel]
accept = 127.0.0.1:5000
# Hier liegen die eben erzeugten lokalen HTTPS-Zertifikate:
cert = /etc/containers/certs.d/harbor.test.slainte.at/local.crt
key = /etc/containers/certs.d/harbor.test.slainte.at/local.key

connect = harbor.test.slainte.at:443
# Hier liegen Ihre echten Harbor-mTLS-Zertifikate:
sslVersion = TLSv1.2
cert = /etc/containers/certs.d/harbor.test.slainte.at/client.cert
key = /etc/containers/certs.d/harbor.test.slainte.at/client.key
EOF

# Start stunnel
stunnel /etc/stunnel/harbor-registry.conf
#

# alfred@lxd:~$ echo ${HARBOR_PASSWORD} | cosign sign --key cosign.key --allow-insecure-registry  localhost:5000/${project}/${image}@${digest}
# Signing artifact... | Pushing signature to: localhost:5000/test/dummy
# Error: signing [localhost:5000/test/dummy@sha256:cc9262030db4a2472ff21e96be7fe4433d4c2ff837782285b215256dec3ac686]: signing digest: Get "https://localhost:5000/v2/": http: server gave HTTP response to HTTPS client; GET http://localhost:5000/v2/: unexpected status code 404 Not Found
# error during command execution: signing [localhost:5000/test/dummy@sha256:cc9262030db4a2472ff21e96be7fe4433d4c2ff837782285b215256dec3ac686]: signing digest: Get "https://localhost:5000/v2/": http: server gave HTTP response to HTTPS client; GET http://localhost:5000/v2/: unexpected status code 404 Not Found


# Der Fehler entsteht, weil Ihr stunnel-Dienst im Klartext-Modus (client = yes) lauscht, 
# cosign aber eine verschlüsselte HTTPS-Verbindung aufbauen möchte.
# Das globale oder Sektions-Flag client = yes bei stunnel bedeutet: „Akzeptiere lokal unverschlüsseltes HTTP und verschlüssele es nach außen.“ 
# Wenn cosign nun ein HTTPS-Paket an localhost:5000 schickt, erwartet stunnel Klartext, versteht den Handshake nicht richtig und antwortet so, dass Go den Fehler server gave HTTP response to HTTPS client wirft. 
# stunnel kann in einer einzelnen Sektion nicht gleichzeitig TLS annehmen und TLS ausgeben.