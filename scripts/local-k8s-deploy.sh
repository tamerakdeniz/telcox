#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KIND_CLUSTER_NAME="${KIND_CLUSTER_NAME:-telcox-local}"
SKIP_BUILD="${SKIP_BUILD:-false}"

cd "${ROOT_DIR}"

if [ "${SKIP_BUILD}" != "true" ]; then
  mvn -B -ntp package -DskipTests
  docker compose build discovery-server config-server api-gateway bff-service
fi

if command -v kind >/dev/null 2>&1 && kind get clusters | grep -qx "${KIND_CLUSTER_NAME}"; then
  kind load docker-image telcox/discovery-server:1.0.0-SNAPSHOT --name "${KIND_CLUSTER_NAME}"
  kind load docker-image telcox/config-server:1.0.0-SNAPSHOT --name "${KIND_CLUSTER_NAME}"
  kind load docker-image telcox/api-gateway:1.0.0-SNAPSHOT --name "${KIND_CLUSTER_NAME}"
  kind load docker-image telcox/bff-service:1.0.0-SNAPSHOT --name "${KIND_CLUSTER_NAME}"
elif command -v minikube >/dev/null 2>&1 && minikube status >/dev/null 2>&1; then
  minikube image load telcox/discovery-server:1.0.0-SNAPSHOT
  minikube image load telcox/config-server:1.0.0-SNAPSHOT
  minikube image load telcox/api-gateway:1.0.0-SNAPSHOT
  minikube image load telcox/bff-service:1.0.0-SNAPSHOT
else
  echo "No running Kind cluster named ${KIND_CLUSTER_NAME} or Minikube profile found; applying manifests with existing image access."
fi

kubectl apply -k k8s/local
kubectl -n telcox-local rollout status deploy/redis --timeout=180s
kubectl -n telcox-local rollout status deploy/kafka --timeout=180s
kubectl -n telcox-local rollout status deploy/discovery-server --timeout=180s
kubectl -n telcox-local rollout status deploy/config-server --timeout=180s
kubectl -n telcox-local rollout status deploy/api-gateway --timeout=180s
kubectl -n telcox-local rollout status deploy/bff-service --timeout=180s
