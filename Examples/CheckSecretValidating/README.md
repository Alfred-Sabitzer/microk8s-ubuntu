# Check Secret Validating Admission Controller

Before deploying configs, some basica have to be checked.

# Check Existence of enabled api's

Please note https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/

This command shows the relevant api-veriosn. It is important, that admissionregistration.k8s.io/v1 is activated and present.

````bash
#slainte@k8s:~$ kubectl api-versions 
acme.cert-manager.io/v1
admissionregistration.k8s.io/v1
apiextensions.k8s.io/v1
apiregistration.k8s.io/v1
apps/v1
authentication.k8s.io/v1
authorization.k8s.io/v1
autoscaling/v1
autoscaling/v2
batch/v1
cert-manager.io/v1
certificates.k8s.io/v1
coordination.k8s.io/v1
crd.projectcalico.org/v1
cstor.openebs.io/v1
discovery.k8s.io/v1
events.k8s.io/v1
flowcontrol.apiserver.k8s.io/v1
flowcontrol.apiserver.k8s.io/v1beta3
metrics.k8s.io/v1beta1
networking.k8s.io/v1
node.k8s.io/v1
openebs.io/v1
openebs.io/v1alpha1
policy/v1
rbac.authorization.k8s.io/v1
scheduling.k8s.io/v1
snapshot.storage.k8s.io/v1
snapshot.storage.k8s.io/v1beta1
storage.k8s.io/v1
v1

````

It is important, that MutatingAdmissionWebhook and ValidatingAdmissionWebhook are activated within the cluster.

````bash
slainte@k8s:~$ cat  /var/snap/microk8s/current/args/kube-apiserver | grep -i enable-admission-plugins
--enable-admission-plugins=EventRateLimit
````
Now we can edit /var/snap/microk8s/current/args/kube-apiserver

````bash
slainte@k8s:~$ cat  /var/snap/microk8s/current/args/kube-apiserver | grep -i enable-admission-plugins
--enable-admission-plugins=EventRateLimit,ValidatingAdmissionPolicy,ValidatingAdmissionWebhook
````

Now System is ready for your configuration.