# Istio egress — Test connection

Test connection over egress

````bash
# Test host direct
curl -k -v http://192.168.0.194:9283/metrics
````

Logon to pod

````bash
kubectl get pods -n istio-system
kubectl exec -it -n istio-system travelping -- sh -c "clear; (bash || ash || sh)"

# Test configured Service
curl -k -v http://prometheus-ceph-external.istio-system.svc.cluster.local:9283/metrics
````
