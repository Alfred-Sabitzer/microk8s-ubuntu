#!/usr/bin/env bash

set -Eeuo pipefail

ACTION="${1:-check}"
ENVIRONMENT_FILE="${2:-duplicity.env}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

die() {
  printf '❌ ERROR: %s\n' "$*" >&2
  exit 1
}

HELM=(sudo microk8s.helm)

main() {
  cd "$SCRIPT_DIR"
  [[ -r "$ENVIRONMENT_FILE" ]] || die "Environment file is not readable: $ENVIRONMENT_FILE"
  # shellcheck disable=SC1090
  source "$ENVIRONMENT_FILE"

  : "${TARGET_NAMESPACE:=duplicity}"
  : "${RELEASE_NAME:=duplicity}"
  : "${tag:=latest}"
  : "${project:=duplicity}"
  : "${image:=duplicity}"
  : "${digest:=}"
  : "${HARBOR_LINK:=harbor.test.slainte.at}"
  : "${SOURCE_BUCKET_INFO:=test-velero}"

  case "$ACTION" in
    install|redeploy)
      "${HELM[@]}" upgrade --install "$RELEASE_NAME" "$SCRIPT_DIR" \
        --namespace "$TARGET_NAMESPACE" \
        --create-namespace \
        --set "namespace=$TARGET_NAMESPACE" \
        --set "image.registry=$HARBOR_LINK" \
        --set "image.tag=$tag" \
        --set "image.project=$project" \
        --set "image.repository=$image" \
        --set "image.digest=$digest" \
        --set "backup.bucket=$SOURCE_BUCKET_INFO"
      ;;
    delete)
      "${HELM[@]}" uninstall --ignore-not-found --namespace "$TARGET_NAMESPACE" "$RELEASE_NAME"
      ;;
    check)
      "${HELM[@]}" list --namespace "$TARGET_NAMESPACE"
      "${HELM[@]}" status --namespace "$TARGET_NAMESPACE" "$RELEASE_NAME" --show-desc --show-resources
      ;;
    check-all)
      "${HELM[@]}" list --namespace "$TARGET_NAMESPACE"
      "${HELM[@]}" get all --namespace "$TARGET_NAMESPACE" "$RELEASE_NAME"
      "${HELM[@]}" get values --namespace "$TARGET_NAMESPACE" "$RELEASE_NAME"
      ;;
    *)
      die "⚠️ Usage: $0 {install|redeploy|delete|check|check-all} [environment-file]"
      ;;
  esac

  log "👍 Helm $ACTION completed successfully"
}

main
