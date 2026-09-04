#!/bin/bash
############################################################################################
#
# Manipulate CoreDNS configuration for Harbor on MicroK8s.
#
############################################################################################
set -euo pipefail
#shopt -o -s xtrace #—Displays each command before it is executed.

cat <<EOF | kubectl apply -f -
apiVersion: v1
data:
  Corefile: |
    .:53 {
        errors
        health {
           lameduck 5s
        }
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
           ttl 30
        }
        
        # --- Make url internal available ---
        #rewrite name harbor.test.slainte.at harbor.harbor.svc.cluster.local
        # -----------------------------------

        prometheus :9153
        forward . /etc/resolv.conf {
           max_concurrent 1000
        }
        cache 30
        loop
        reload
        loadbalance
    }
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
EOF
kubectl rollout restart deployment -n kube-system coredns
exit