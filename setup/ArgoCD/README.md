# ArgoCD Benutzer-Anlage
Dokumentation der notwendigen Schritte

Installation ArgoCD am Rechner nach https://argo-cd.readthedocs.io/en/stable/cli_installation/

```bash
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
```
Danach holen wir uns die IP des Service

```bash
kubectl get services -n argocd
NAME                                       TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
argo-cd-argocd-application-controller      ClusterIP   10.152.183.254   <none>        8082/TCP            19d
argo-cd-argocd-redis                       ClusterIP   10.152.183.230   <none>        6379/TCP            19d
argo-cd-argocd-dex-server                  ClusterIP   10.152.183.186   <none>        5556/TCP,5557/TCP   19d
argo-cd-argocd-applicationset-controller   ClusterIP   10.152.183.69    <none>        7000/TCP            19d
argo-cd-argocd-server                      ClusterIP   10.152.183.141   <none>        80/TCP,443/TCP      19d
argo-cd-argocd-repo-server                 ClusterIP   10.152.183.39    <none>        8081/TCP            19d
```

Dann loggen wir uns ein

```bash
argocd login 10.152.183.141 --username admin
WARNING: server certificate had error: x509: cannot validate certificate for 10.152.183.141 because it doesn't contain any IP SANs. Proceed insecurely (y/n)? y
Password:
'admin:login' logged in successfully
Context '10.152.183.141' updated
```

Nun können wir die User (die in den Configmaps konfiguriert sind) mit einem Passwort ausstatten.

```bash
argocd account update-password --account alfred --new-password <new-password>
```
