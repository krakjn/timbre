#!/bin/bash
set -e

# Default values
DOCKER_REGISTRY=${DOCKER_REGISTRY:-"ghcr.io/krakjn"}
VERSION=${VERSION:-$(cat pkg/version.txt | tr -d '[:space:]')}
NAMESPACE=${NAMESPACE:-"timbre"}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --registry)
      DOCKER_REGISTRY="$2"
      shift 2
      ;;
    --version)
      VERSION="$2"
      shift 2
      ;;
    --namespace)
      NAMESPACE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

cat <<EOF
Deploying Timbre to Kubernetes
------------------------------
Version:         ${VERSION}
Docker Registry: ${DOCKER_REGISTRY}
Namespace:       ${NAMESPACE}
-----------------------------
EOF

# Create namespace
kubectl apply -f k8s/namespace.yaml

# Apply Kubernetes configs
for file in k8s/*.yaml; do
  if [[ "$file" != "k8s/namespace.yaml" && "$file" != "k8s/kind-config.yaml" ]]; then
    echo "Applying ${file}..."
    sed -e "s|\${DOCKER_REGISTRY}|$DOCKER_REGISTRY|g" \
        -e "s|\${VERSION}|$VERSION|g" \
        -e "s|namespace: timbre|namespace: $NAMESPACE|g" \
        "$file" | kubectl apply -f -
  fi
done

echo "Waiting for pods to be ready..."
kubectl get pods -n $NAMESPACE -l app=timbre -w

echo "deployed to: http://localhost:30000"

echo "Pod status:"
kubectl get pods -n $NAMESPACE -l app=timbre

POD_NAME=$(kubectl get pods -n $NAMESPACE -l app=timbre -o jsonpath="{.items[0].metadata.name}")

echo "Logs from pod ${POD_NAME}:"
kubectl logs $POD_NAME -n $NAMESPACE 