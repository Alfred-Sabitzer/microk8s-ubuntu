# MicoK8SDashboard

Enable (core) The Kubernetes dashboard

Please consider https://microk8s.io/docs/addon-dashboard

# Local /etc/hosts

Dashborad weill be available at. https://kubernetes-dashboard.127.0.0.1.nip.io
Enter this into your local /etc/hosts. eg:

```bash
192.168.10.104  kubernetes-dashboard.127.0.0.1.nip.io
```

# For MicroK8s 1.24 or newer

Note: tokens with a long life are maybe not very secure.

```bash
microk8s kubectl create token cluster-admin -n kube-system --duration=8760h
```
This token has to be added to .kube/config.
Please consider https://kubernetes.io/docs/reference/kubectl/generated/kubectl_create/kubectl_create_token/
and https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-token/ 

This Token can be used to identify on the dashboard

# Role cluster-admin

please Note: Cluser-Admin is a very powerful role. For differente purposes consider to create different service accounts (eg. binded to role *view* )

```bash
slainte@k8s:~/alfred/setup/MicroK8SCertManager$ k get clusterroles.rbac.authorization.k8s.io
NAME                                                                   CREATED AT
coredns                                                                2024-07-15T12:56:16Z
calico-kube-controllers                                                2024-07-15T12:56:18Z
calico-node                                                            2024-07-15T12:56:18Z
cluster-admin                                                          2024-07-15T12:58:33Z
system:discovery                                                       2024-07-15T12:58:33Z
system:monitoring                                                      2024-07-15T12:58:33Z
system:basic-user                                                      2024-07-15T12:58:33Z
system:public-info-viewer                                              2024-07-15T12:58:33Z
system:aggregate-to-admin                                              2024-07-15T12:58:34Z
system:aggregate-to-edit                                               2024-07-15T12:58:34Z
system:aggregate-to-view                                               2024-07-15T12:58:34Z
system:heapster                                                        2024-07-15T12:58:34Z
system:node                                                            2024-07-15T12:58:34Z
system:node-problem-detector                                           2024-07-15T12:58:34Z
system:kubelet-api-admin                                               2024-07-15T12:58:34Z
system:node-bootstrapper                                               2024-07-15T12:58:34Z
system:auth-delegator                                                  2024-07-15T12:58:34Z
system:kube-aggregator                                                 2024-07-15T12:58:34Z
system:kube-controller-manager                                         2024-07-15T12:58:34Z
system:kube-dns                                                        2024-07-15T12:58:34Z
system:persistent-volume-provisioner                                   2024-07-15T12:58:34Z
system:certificates.k8s.io:certificatesigningrequests:nodeclient       2024-07-15T12:58:34Z
system:certificates.k8s.io:certificatesigningrequests:selfnodeclient   2024-07-15T12:58:34Z
system:volume-scheduler                                                2024-07-15T12:58:34Z
system:certificates.k8s.io:legacy-unknown-approver                     2024-07-15T12:58:34Z
system:certificates.k8s.io:kubelet-serving-approver                    2024-07-15T12:58:34Z
system:certificates.k8s.io:kube-apiserver-client-approver              2024-07-15T12:58:34Z
system:certificates.k8s.io:kube-apiserver-client-kubelet-approver      2024-07-15T12:58:34Z
system:service-account-issuer-discovery                                2024-07-15T12:58:34Z
system:node-proxier                                                    2024-07-15T12:58:34Z
system:kube-scheduler                                                  2024-07-15T12:58:34Z
system:controller:attachdetach-controller                              2024-07-15T12:58:34Z
system:controller:clusterrole-aggregation-controller                   2024-07-15T12:58:34Z
system:controller:cronjob-controller                                   2024-07-15T12:58:34Z
system:controller:daemon-set-controller                                2024-07-15T12:58:34Z
system:controller:deployment-controller                                2024-07-15T12:58:34Z
system:controller:disruption-controller                                2024-07-15T12:58:34Z
system:controller:endpoint-controller                                  2024-07-15T12:58:34Z
system:controller:endpointslice-controller                             2024-07-15T12:58:34Z
system:controller:endpointslicemirroring-controller                    2024-07-15T12:58:34Z
system:controller:expand-controller                                    2024-07-15T12:58:34Z
system:controller:ephemeral-volume-controller                          2024-07-15T12:58:34Z
system:controller:generic-garbage-collector                            2024-07-15T12:58:34Z
system:controller:horizontal-pod-autoscaler                            2024-07-15T12:58:34Z
system:controller:job-controller                                       2024-07-15T12:58:34Z
system:controller:namespace-controller                                 2024-07-15T12:58:34Z
system:controller:node-controller                                      2024-07-15T12:58:34Z
system:controller:persistent-volume-binder                             2024-07-15T12:58:34Z
system:controller:pod-garbage-collector                                2024-07-15T12:58:34Z
system:controller:replicaset-controller                                2024-07-15T12:58:34Z
system:controller:replication-controller                               2024-07-15T12:58:34Z
system:controller:resourcequota-controller                             2024-07-15T12:58:34Z
system:controller:route-controller                                     2024-07-15T12:58:34Z
system:controller:service-account-controller                           2024-07-15T12:58:34Z
system:controller:service-controller                                   2024-07-15T12:58:34Z
system:controller:statefulset-controller                               2024-07-15T12:58:34Z
system:controller:ttl-controller                                       2024-07-15T12:58:34Z
system:controller:certificate-controller                               2024-07-15T12:58:34Z
system:controller:pvc-protection-controller                            2024-07-15T12:58:34Z
system:controller:pv-protection-controller                             2024-07-15T12:58:34Z
system:controller:ttl-after-finished-controller                        2024-07-15T12:58:34Z
system:controller:root-ca-cert-publisher                               2024-07-15T12:58:34Z
system:controller:legacy-service-account-token-cleaner                 2024-07-15T12:58:34Z
openebs-jiva-csi-cluster-registrar-role                                2024-07-15T13:01:51Z
openebs-jiva-csi-registrar-role                                        2024-07-15T13:01:51Z
openebs-jiva-csi-attacher-role                                         2024-07-15T13:01:51Z
openebs-cstor-migration                                                2024-07-15T13:01:51Z
openebs-cstor-operator                                                 2024-07-15T13:01:51Z
openebs-cstor-csi-snapshotter-role                                     2024-07-15T13:01:51Z
openebs                                                                2024-07-15T13:01:51Z
openebs-cstor-csi-cluster-registrar-role                               2024-07-15T13:01:51Z
jiva-operator                                                          2024-07-15T13:01:51Z
openebs-cstor-csi-attacher-role                                        2024-07-15T13:01:51Z
openebs-cstor-csi-registrar-role                                       2024-07-15T13:01:51Z
openebs-cstor-csi-provisioner-role                                     2024-07-15T13:01:51Z
openebs-jiva-csi-provisioner-role                                      2024-07-15T13:01:51Z
openebs-jiva-csi-snapshotter-role                                      2024-07-15T13:01:52Z
cert-manager-cainjector                                                2024-07-15T13:04:38Z
cert-manager-controller-issuers                                        2024-07-15T13:04:38Z
cert-manager-controller-clusterissuers                                 2024-07-15T13:04:38Z
cert-manager-controller-certificates                                   2024-07-15T13:04:38Z
cert-manager-controller-orders                                         2024-07-15T13:04:38Z
cert-manager-controller-challenges                                     2024-07-15T13:04:38Z
cert-manager-controller-ingress-shim                                   2024-07-15T13:04:38Z
cert-manager-view                                                      2024-07-15T13:04:38Z
view                                                                   2024-07-15T12:58:34Z
cert-manager-edit                                                      2024-07-15T13:04:38Z
edit                                                                   2024-07-15T12:58:34Z
admin                                                                  2024-07-15T12:58:34Z
cert-manager-controller-approve:cert-manager-io                        2024-07-15T13:04:38Z
cert-manager-controller-certificatesigningrequests                     2024-07-15T13:04:38Z
cert-manager-webhook:subjectaccessreviews                              2024-07-15T13:04:38Z
microk8s-hostpath                                                      2024-07-15T13:13:47Z
slainte@k8s:~/alfred/setup/MicroK8SCertManager$ 
```
