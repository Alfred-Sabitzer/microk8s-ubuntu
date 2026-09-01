export TARGET_NAMESPACE="production"

helm upgrade --install my-app ./app-deployment \
  --create-namespace \
  --set namespace="${TARGET_NAMESPACE}" \
  --set image.registry="${HARBOR_LINK}" \
  --set buildInfo.tool="${build}" \
  --set image.tag="${tag}" \
  --set image.project="${project}" \
  --set image.repository="${image}" \
  --set image.digest="${digest}" \
  --set registryCredentials.username="${HARBOR_USER}" \
  --set registryCredentials.password="${HARBOR_PASSWORD}"
