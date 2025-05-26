# Check Secret Validating Admission Controller

This Validating admission controller checks the right syntax of Secret Definitions. Code is based on the example https://dev.to/douglasmakey/implementing-a-simple-k8s-admission-controller-in-go-2dcg

# Preparation

You have to create a secret for containing the certificate for your controller.


CA_BUNDLE=$(cat /var/snap/microk8s/current/certs/ca.crt | base64 | tr -d '\n')


# Deployment 

