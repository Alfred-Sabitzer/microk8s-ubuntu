# Build
export HARBOR_LINK="harbor.test.slainte.at"
export build="podman"
export tag="20261123"
export project="duplicati"
export image="duplicati"
export digest="sha256:4ad2de747968bacb9dc8d372c34f2450593c8fb8deeb6a08f703431344b8daa2"
# Build and push the image to Harbor

export SECRET_NAME=$(sudo microk8s kubectl get secret -n "$project" | grep dvb-claim-credentials | awk '{print $1}')
export SECRET_KEY=$(sudo microk8s kubectl get secret "$DUPLICITY_SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data.BucketInfo}' | base64 --decode)


printf '%s' "$HARBOR_PASSWORD" | "${build}" login "$HARBOR_LINK" -u "$HARBOR_USER" --password-stdin


"${build}" pull "$HARBOR_LINK"/"$project"/"$image"@"$digest"
