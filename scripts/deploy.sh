#!/bin/bash
set -e

# Default values
DOCKER_REGISTRY=${DOCKER_REGISTRY:-"ghcr.io/krakjn"}
VERSION=${VERSION:-$(cat pkg/version.txt)}
NAMESPACE=${NAMESPACE:-"default"}

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

echo "Deploying Timbre version $VERSION to Kubernetes..."
echo "Docker Registry: $DOCKER_REGISTRY"
echo "Namespace: $NAMESPACE"

# Check if namespace exists, create if not
if ! kubectl get namespace $NAMESPACE &> /dev/null; then
  echo "Creating namespace $NAMESPACE..."
  kubectl create namespace $NAMESPACE
fi

# Process template files and apply to cluster
for file in k8s/*.yaml; do
  echo "Applying $file..."
  sed -e "s|\${DOCKER_REGISTRY}|$DOCKER_REGISTRY|g" \
      -e "s|\${VERSION}|$VERSION|g" \
      "$file" | kubectl apply -f - -n $NAMESPACE
done

# Wait for deployment to be ready
echo "Waiting for deployment to be ready..."
kubectl rollout status deployment/timbre -n $NAMESPACE --timeout=300s

echo "Deployment complete!"
echo "To access the application, use: http://localhost:30000"

# Show pod status
echo "Pod status:"
kubectl get pods -n $NAMESPACE -l app=timbre

# Show logs from the first pod
POD_NAME=$(kubectl get pods -n $NAMESPACE -l app=timbre -o jsonpath="{.items[0].metadata.name}")
echo "Logs from pod $POD_NAME:"
kubectl logs $POD_NAME -n $NAMESPACE 