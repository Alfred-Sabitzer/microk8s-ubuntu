# Istio egress — Test connection

Test connection over egress


````bash
# Test host direct
curl -k -v http://192.168.0.194:9283/metrics
# Test host direct
curl -k -v http://rook-ceph-external.local:9283/metrics

````
Logon to pod

````bash
kubectl get pods -n rook-ceph
kubectl exec -it -n "rook-ceph" travelping -- sh -c "clear; (bash || ash || sh)"
````
