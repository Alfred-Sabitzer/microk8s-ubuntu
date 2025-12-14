1️⃣ TLS-Zertifikat (Beispiel mit cert-manager)
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: app-intern-tls
  namespace: istio-system
spec:
  secretName: app-intern-tls
  issuerRef:
    name: internal-ca
    kind: ClusterIssuer
  dnsNames:
    - app.intern.example.com

2️⃣ Istio Gateway (Kubernetes Gateway API)

👉 HTTPS only, Gateway API, interne IP-Ranges eingeschränkt

apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: intern-https-gateway
  namespace: istio-system
  annotations:
    # Beschränkt externe Zugriffe auf interne Netze (Cloud / MetalLB / LB abhängig)
    service.beta.kubernetes.io/load-balancer-source-ranges: |
      10.0.0.0/8,
      172.16.0.0/12,
      192.168.0.0/16
spec:
  gatewayClassName: istio
  listeners:
    - name: https
      hostname: app.intern.example.com
      port: 443
      protocol: HTTPS
      tls:
        mode: Terminate
        certificateRefs:
          - kind: Secret
            name: app-intern-tls
      allowedRoutes:
        namespaces:
          from: Same


🔐 Sicherheitsmerkmale

❌ Kein HTTP

✅ TLS-Termination

✅ Nur definierter Hostname

✅ Nur interne IP-Ranges

✅ Routes nur aus gleichem Namespace

3️⃣ HTTPRoute (Routing zur Anwendung)
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: app-route
  namespace: istio-system
spec:
  parentRefs:
    - name: intern-https-gateway
  hostnames:
    - app.intern.example.com
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: my-app-service
          port: 8080

4️⃣ Optional: Zusätzliche Absicherung (empfohlen)
🔒 Istio AuthorizationPolicy (nur interne CIDRs)
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-internal-only
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  action: ALLOW
  rules:
    - from:
        - source:
            ipBlocks:
              - 10.0.0.0/8
              - 172.16.0.0/12
              - 192.168.0.0/16

5️⃣ Architektur-Überblick
[ Internal Client ]
        |
   HTTPS (443)
        |
[ Istio Gateway (Gateway API) ]
        |
[ HTTPRoute ]
        |
[ Service / Pod ]

✅ Ergebnis

🔐 HTTPS only

🌐 Externer DNS-Name

🛡️ Zugriff nur aus internen Netzwerken

📦 Standardkonforme Kubernetes Gateway API

🚀 Voll kompatibel mit Istio

Wenn du willst, kann ich dir das auch für mTLS, MetalLB, MicroK8s, Keycloak (OIDC) oder Zero-Trust (JWT + OPA) erweitern.

bitte mit mTLS, MetalLB und MicroK8s. Bitte benutze  gateway.networking.k8s.io/v1 als api

Perfekt – unten findest du ein vollständiges, konsistentes Beispiel für ein Istio Gateway mit Kubernetes Gateway API v1, mTLS, MetalLB und MicroK8s.
Der Fokus liegt klar auf Security by default und interner Erreichbarkeit.

🔐 Zielarchitektur (Kurzfassung)

MicroK8s mit:

microk8s enable istio metallb cert-manager dns

MetalLB stellt eine interne LoadBalancer-IP

Istio Gateway API (v1)

HTTPS + mTLS

Zugriff nur aus internen CIDRs

Zero Trust: Client-Zertifikat zwingend erforderlich

0️⃣ Voraussetzungen (MicroK8s)
microk8s enable istio metallb cert-manager


MetalLB IP-Pool (intern):

apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: internal-pool
  namespace: metallb-system
spec:
  addresses:
    - 192.168.10.200-192.168.10.210
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: internal-l2
  namespace: metallb-system

1️⃣ Interne CA für mTLS (cert-manager)
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: internal-ca
spec:
  selfSigned: {}

# Hier wird es interessant


2️⃣ Server-Zertifikat für Gateway (TLS + mTLS)
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: app-intern-gateway-cert
  namespace: istio-system
spec:
  secretName: app-intern-gateway-tls
  issuerRef:
    name: internal-ca
    kind: ClusterIssuer
  dnsNames:
    - app.intern.example.com
  usages:
    - digital signature
    - key encipherment
    - server auth

3️⃣ Client-CA-Zertifikat (für mTLS Clients)
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: client-ca
  namespace: istio-system
spec:
  isCA: true
  secretName: client-ca-cert
  issuerRef:
    name: internal-ca
    kind: ClusterIssuer
  commonName: internal-clients

4️⃣ Istio Gateway (Gateway API v1, HTTPS + mTLS)
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: intern-mtls-gateway
  namespace: istio-system
  annotations:
    metallb.universe.tf/address-pool: internal-pool
    service.beta.kubernetes.io/load-balancer-source-ranges: |
      10.0.0.0/8,
      172.16.0.0/12,
      192.168.0.0/16
spec:
  gatewayClassName: istio
  listeners:
    - name: https-mtls
      hostname: app.intern.example.com
      port: 443
      protocol: HTTPS
      tls:
        mode: Mutual
        certificateRefs:
          - kind: Secret
            name: app-intern-gateway-tls
        caCertificateRefs:
          - kind: Secret
            name: client-ca-cert
      allowedRoutes:
        namespaces:
          from: Same


✅ Ergebnis

HTTPS zwingend

Client-Zertifikat zwingend

Nur interne Netze

MetalLB vergibt interne IP

5️⃣ HTTPRoute (Gateway API v1)
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: app-route
  namespace: istio-system
spec:
  parentRefs:
    - name: intern-mtls-gateway
  hostnames:
    - app.intern.example.com
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: my-app-service
          port: 8080

6️⃣ Istio PeerAuthentication (STRICT mTLS intern)
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system
spec:
  mtls:
    mode: STRICT

7️⃣ Zusätzliche Absicherung: AuthorizationPolicy (CIDR + mTLS)
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-internal-only
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  action: ALLOW
  rules:
    - from:
        - source:
            ipBlocks:
              - 10.0.0.0/8
              - 172.16.0.0/12
              - 192.168.0.0/16
      when:
        - key: request.auth.principal
          values: ["*"]

8️⃣ Client-Test (Beispiel)
curl https://app.intern.example.com \
  --cert client.crt \
  --key client.key \
  --cacert ca.crt


❌ Ohne Client-Zertifikat → TLS Handshake schlägt fehl

🧠 Sicherheitsniveau
Feature	Status
Gateway API v1	✅
HTTPS only	✅
mTLS (Client Auth)	✅
Interne IPs	✅
MetalLB intern	✅
Zero Trust	✅
MicroK8s ready	✅

Wenn du möchtest, kann ich dir das als Architekturdiagramm, Office-Dokument, Helm-Chart, ArgoCD-App oder mit Keycloak (mTLS + OIDC) ausarbeiten.

Gefällt dir diese Persönlichkeit?




ChatGPT kann Fehler machen. Überprüfe wichtige Informationen. Siehe Cookie-Voreinstellungen.