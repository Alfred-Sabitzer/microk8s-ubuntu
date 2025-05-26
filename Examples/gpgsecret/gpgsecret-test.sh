#!/bin/bash
############################################################################################
# Test Running Service
############################################################################################
#shopt -o -s errexit	#—Terminates  the shell	script if a	command	returns	an error code.
#shopt -o -s xtrace	#—Displays each	command	before it’s	executed.
shopt -o -s nounset	#-No Variables without definition
shopt -s dotglob # exclude hidden directories
IFS="
"

clear

#get pod
pod=$(kubectl get pods -n gpg | awk '{print $1}'  | grep -i gpgsecret)
podip=$(kubectl get pods -n gpg "${pod}" -o jsonpath='{.status.podIP}')
#kubectl rollout restart -n gpg deployment gpgsecret
#kill pod
kubectl delete -n gpg pod "${pod}"

#get pod
pod=""
podip=""
while [ "${podip}x"  == "x" ]
do
  echo "Try to get ip ${pod} ${podip}"
  sleep 1
  pod=$(kubectl get pods -n gpg | awk '{print $1}'  | grep -i gpgsecret)
  podip=$(kubectl get pods -n gpg "${pod}" -o jsonpath='{.status.podIP}')
done
curl --request POST --header  "Content-Type: application/json" --data @/tmp/mytext.json -k -v  http://"${podip}"/encrypt
kubectl logs -n gpg "${pod}"

exit


# test pod
### curl http://"${podip}"/status
# {"noencrypt":"1","nodecrypt":"5","version":"1.17.12","doku":"https://gitlab.com/Alfred-Sabitzer/microk8s-ubuntu/-/tree/master/gpgsecret?ref_type=heads"}
### kubectl logs -n gpg "${pod}"

mytext=$(echo 'verysecrettext' | base64 -w 0)
echo "encrypt{\"text\": \"${mytext}\"}" > /tmp/mytext.json

myencrypt=$(curl --request POST --header  "Content-Type: application/json" --data @/tmp/mytext.json -k -v  http://"${podip}"/encrypt)
# {"text":"LS0tLS1CRUdJTiBQR1AgTUVTU0FHRS0tLS0tCgogIGhRSU1Bd3VlbE1yeURpbFVBUS85Rm5PSTYyWUY0OW5qbUdlS0sxS29HTFNKSCsrZlJTUXlQQ3NPNkhCMlpCS1gKICBXbmtZSEd4dDhTV2VYc3IxVmdyOFNBVzZub0NlNmdkK1VHcmF1STRJWUh5dHI4QUdwYlF3aUtkUk13dVVHZlkrCiAgek1MT1JBYVBabkFmRUQzbXR6TWdhaGtTRVRDVXNVelU4UG9WcFhBY2RZSEpraEs3TXN2Tmh4UnhBNmJWc1l5SgogIEpvc1FqSG9IQzEzV1NmODlMWDFRTmxKS01GSWpqdm5qNXo5M1FFaUpPRVJDSTZHT3ZGK3F2M2pCZU5wZGpHaFEKICBMRHhHTlR5dFFOaUc2anp6SXNKV1VCVGdFT3VFYVBHaFNsWjJBWERQV00wMk1rVXdkbUIwV1A3Y3Zrb0RlbjV0CiAgK3FVUGZ1Qkhwa0NmdE5FZVFjZ3BHdlI4YnNIZWtLRVhIZHc5YUQ3NWJnSkxxeWQ2dE1JWitXd0xZaGs4SlZodAogIENWRytxL2NvZWpYSnV4UGhCMCtGeldRY0dNdXRkVGJQSDNiNS8vYUVmekJqRUY1dlFxL09aMm15SUU3Q3grSzMKICB0eFFyMUNXYWRXMEhCdDFvQ1BYbVNUdXV4SExXZTdEZm9rdUdLU3BlczFUVXEzZHYwWUNUeUxYQzhkNWR6OGIxCiAgbWNCT3NQMVpNVlo5UXJQZWN5TWhTSHVKY2U2b0xTYTN2cExpRytzSlJOZGxsMFIxTlYyaUdnOEgvS0RRZERqKwogIDBFQnZiL2ZTLzZGOWludkVXTjhZc24wSjJrTkI0L3I1bWVrYkdpbDluZC9xT0grMHEzUGFRb3ppUVI0cDl0eHAKICBPeDgvNlhNNnM5cnJRQWRQeGVwaWJFMFYzU084UWF6VlZQYlRxSTJ5R3J0R3JUdURtVy92MVRoUWR0emxuVkhTCiAgVmdHWUoxMUdiUlRaQ1doRE55R2NneGtwRTIvYTAvbThmdXJscGliQytkM0I4MG9FWDBPdSs1TldtM0N5WHpxVQogIEU5U3pxbFNPZ3owb3RuaUEwSzgrSnMyRkNRUVJwc3FGb1lZblpoQjcveVJWOFZOSy9aK0sKICA9US9ScQogIC0tLS0tRU5EIFBHUCBNRVNTQUdFLS0tLS0K"}
echo "${myencrypt}" > /tmp/myencrypt.json
echo "Encrypt: ${myencrypt}"
kubectl logs -n gpg "${pod}"

exit

mydecrypt=$(curl --request POST --header  "Content-Type: application/json" --data @/tmp/myencrypt.json -k -v  http://"${podip}"/decrypt)
#{"text":"dmVyeXNlY3JldHRleHQK"}
echo "Decrypt: ${mydecrypt}"
kubectl logs -n gpg "${pod}"

exit
