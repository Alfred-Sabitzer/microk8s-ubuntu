# MicroK8SRegistry

Enable core registry.
This registry needs the hostpath-addon, and is onyl available on one node (in case of a cluster).

Please consider https://microk8s.io/docs/registry-built-in and https://stackoverflow.com/questions/59804772/push-docker-image-to-registry-installed-using-microk8s-addon

Please do not forget to update your hosts-file and docker-configs accordingly.

# Local Setup

On your "development computer" please ensure that you are in sync with the 

````bash
cat  /etc/hsots

192.168.10.104  k8s
192.168.10.104  k8s.slainte.at
192.168.10.104  kubernetes-dashboard.127.0.0.1.nip.io
192.168.10.104	registry.k8s.slainte.at

###mkdir -p /etc/docker
###/etc/docker/daemon.json
````

Please consider https://microk8s.io/docs/registry-private

# Test Build

Functionality of your registry can be tested with test-scripts

````bash
./test_registry.sh # Show all repositories and tags
./test_build_docker.sh # create a busybox docker 
````
# Test Deploy

````bash
kubectl apply -f busybox.yaml
````

This deploys a pod into kubernetes.

# Test in Browser:

http://registry.k8s.slainte.at/v2/

# DNS Setup

k8s.slainte.at and registry.k8s.slainte.at have to be known to the internert via dns and have to be routed to the kubernetes cluster (otherwise letsencrypt will not work).


