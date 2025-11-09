# Istio egress — Test connection

Test connection over egress

````bash
# Test host direct
curl -k -v http://192.168.0.192:6789
*   Trying 192.168.0.192:6789...
* Connected to 192.168.0.192 (192.168.0.192) port 6789
> GET / HTTP/1.1
> Host: 192.168.0.192:6789
> User-Agent: curl/8.5.0
> Accept: */*
> 
* Received HTTP/0.9 when not allowed
* Closing connection
curl: (1) Received HTTP/0.9 when not allowed

````
Logon to pod

````bash
kubectl get pods -n rook-ceph
kubectl exec -it -n rook-ceph travelping -- sh -c "clear; (bash || ash || sh)"

# Test configured Service
bash-5.1# curl -k -f http://rook-ceph.rook-ceph.svc.cluster.local:6789
curl: (22) The requested URL returned error: 502 Bad Gateway

````
