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
------------------------------
EOF

# Apply namespace first
cat <<EOF

Creating namespace ${NAMESPACE}...
EOF

kubectl apply -f k8s/namespace.yaml

# Process template files and apply to cluster
for file in k8s/*.yaml; do
  if [[ "$file" != "k8s/namespace.yaml" && "$file" != "k8s/kind-config.yaml" ]]; then
    cat <<EOF

Applying ${file}...
EOF
    
    sed -e "s|\${DOCKER_REGISTRY}|$DOCKER_REGISTRY|g" \
        -e "s|\${VERSION}|$VERSION|g" \
        -e "s|namespace: timbre|namespace: $NAMESPACE|g" \
        "$file" | kubectl apply -f -
  fi
done

cat <<EOF

Waiting for deployment to be ready...
EOF

kubectl rollout status deployment/timbre -n $NAMESPACE --timeout=300s

cat <<EOF

Deployment complete!
To access the application, use: http://localhost:30000

EOF

# Show pod status
cat <<EOF
Pod status:
EOF

kubectl get pods -n $NAMESPACE -l app=timbre

# Show logs from the first pod
POD_NAME=$(kubectl get pods -n $NAMESPACE -l app=timbre -o jsonpath="{.items[0].metadata.name}")

cat <<EOF

Logs from pod ${POD_NAME}:
EOF

kubectl logs $POD_NAME -n $NAMESPACE 