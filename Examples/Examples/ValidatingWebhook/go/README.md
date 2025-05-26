# Validating WebHook

Build and Deply all go-modules

Example is based on https://github.com/douglasmakey/admissioncontroller

## build

A MultiStage-Build is used. Example is from https://github.com/pavel-fokin/go-patterns/blob/main/minimal-docker/Dockerfile.xsmall 

````bash
./do.sh
````
This command will build and store the artefact into docker-repository.

## Go Requirements

https://golangbot.com/go-packages/




## Go Requirements

https://golangbot.com/go-packages/

````bash
./go.sh
````
This will build all go modules and create a local executable.


slainte@k8s:~/alfred/ValidatingWebhook/k8s$ nano x1.yaml
slainte@k8s:~/alfred/ValidatingWebhook/k8s$ k apply -f x1.yaml
Error from server (InternalError): error when creating "x1.yaml": Internal error occurred: failed calling webhook "validatingwebhook-pod-validation.slainte.at": failed to call webhook: Post "https://validatingwebhook-admission-svc.slainte.svc:443/validate/pods?timeout=10s": tls: failed to verify certificate: x509: certificate is valid for k8s.slainte.at, not validatingwebhook-admission-svc.slainte.svc
slainte@k8s:~/alfred/ValidatingWebhook/k8s$ 


slainte@k8s:~/alfred/ValidatingWebhook/k8s$ k apply -f p1.yaml
Error from server (InternalError): error when creating "p1.yaml": Internal error occurred: failed calling webhook "k8s.slainte.at": failed to call webhook: Post "https://validatingwebhook-admission-svc.slainte.svc:443/validate/pods?timeout=10s": tls: failed to verify certificate: x509: certificate is valid for k8s.slainte.at, not validatingwebhook-admission-svc.slainte.svc
slainte@k8s:~/alfred/ValidatingWebhook/k8s$ 


