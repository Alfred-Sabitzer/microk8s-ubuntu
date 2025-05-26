# Create Admission Controller

Example is based on https://www.civo.com/learn/kubernetes-admission-controllers-for-beginners

# Story

````bash
slainte@k8s:~$ mkdir mutating
slainte@k8s:~$ cd mutating/
slainte@k8s:~/mutating$ nano certs.yaml
slainte@k8s:~/mutating$ k apply -f certs.yaml 
clusterissuer.cert-manager.io/selfsigned-issuer unchanged
certificate.cert-manager.io/mutating-replicant created
issuer.cert-manager.io/mutant-issuer created
slainte@k8s:~/mutating$ kubectl get certificates 
NAME                 READY   SECRET        AGE
mutating-replicant   True    root-secret   42s
slainte@k8s:~/mutating$ nano controller.yaml
slainte@k8s:~/mutating$ k apply -f controller.yaml 
deployment.apps/mutating-replicant created
service/mutating-replicant created
slainte@k8s:~/mutating$ kubectl get deployment/mutating-replicant
NAME                 READY   UP-TO-DATE   AVAILABLE   AGE
mutating-replicant   1/1     1            1           2m12s
slainte@k8s:~/mutating$ nano mutating-webhook.yaml
slainte@k8s:~/mutating$ k apply -f mutating-webhook.yaml 
mutatingwebhookconfiguration.admissionregistration.k8s.io/mutate-replicas created
slainte@k8s:~/mutating$ kubectl get mutatingwebhookconfigurations.admissionregistration.k8s.io
NAME                   WEBHOOKS   AGE
cert-manager-webhook   1          115d
mutate-replicas        1          15s
slainte@k8s:~/mutating$ nano sample.yaml
slainte@k8s:~/mutating$ k apply -f sample.yaml 
deployment.apps/whoami created
slainte@k8s:~/mutating$ kubectl get deployment/whoami 
NAME     READY   UP-TO-DATE   AVAILABLE   AGE
whoami   3/3     3            3           17s
slainte@k8s:~/mutating$ kubectl logs deploy/mutating-replicant
2024/11/08 16:01:26 INFO loading certs..
2024/11/08 16:01:26 INFO successfully loaded certs. Starting server... port=9093
2024/11/08 16:05:33 INFO recieved new mutate request
2024/11/08 16:05:33 INFO mutation complete "deployment mutated"=whoami
slainte@k8s:~/mutating$ 
````
This sequence will create a mutating Webhook and deploys a test-deployment.