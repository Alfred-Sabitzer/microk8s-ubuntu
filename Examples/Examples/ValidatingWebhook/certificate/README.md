# Create Admission  Certificate

This scripts are generating the right certificates.
Example is based on https://www.civo.com/learn/kubernetes-admission-controllers-for-beginners
and  https://github.com/alex-leonhardt/k8s-mutate-webhook/blob/master/ssl/ssl.sh 

You have to create a secret for containing the certificate for your controller.

````bash
./demo_certificate.sh
./ssh.sh
````

This scripts will create a valid certificate.

*** This is somehow oldfashioned ***

*** It is more comfortable to use cert-manager ***
