# Istio egress — Test connection

Test connection over egress

````bash
# Test host direct
curl -k -v http://192.168.0.194:9283/metrics
````
Logon to pod

````bash
kubectl get pods -n observability
kubectl exec -it -n observability travelping -- sh -c "clear; (bash || ash || sh)"

# Test configured Service
bash-5.1# curl -k -f http://prometheusceph.observability.svc.cluster.local:9283
<!DOCTYPE html>
<html>
    <head><title>Ceph Exporter</title></head>
    <body>
        <h1>Ceph Exporter</h1>
        <p><a href='/metrics'>Metrics</a></p>
    </body>
</html>

bash-5.1# curl -k -f http://prometheusceph.observability.svc.cluster.local:9283/metrics

# HELP ceph_health_status Cluster health status
# TYPE ceph_health_status untyped
ceph_health_status 0.0
# HELP ceph_mon_quorum_status Monitors in quorum
# TYPE ceph_mon_quorum_status gauge
ceph_mon_quorum_status{ceph_daemon="mon.micro4.slainte.at"} 1.0
ceph_mon_quorum_status{ceph_daemon="mon.micro1.slainte.at"} 1.0

...

````
