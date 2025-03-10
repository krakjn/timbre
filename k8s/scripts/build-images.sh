#!/bin/bash
set -e

# Default values
DOCKER_REGISTRY=${DOCKER_REGISTRY:-"ghcr.io/krakjn"}
VERSION=$(cat pkg/version.txt | tr -d '[:space:]')
PUSH=${PUSH:-false}

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
    --push)
      PUSH=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

cat <<EOF
Building Timbre Docker images
-----------------------------
Version:         ${VERSION}
Docker Registry: ${DOCKER_REGISTRY}
Push:            ${PUSH}
-----------------------------
EOF

# Enable Docker experimental features for manifest support
export DOCKER_CLI_EXPERIMENTAL=enabled

# Build images for each architecture
cat <<EOF

Building x86_64 (amd64) image...
EOF

docker build \
  --build-arg ARCH=x86_64 \
  -t ${DOCKER_REGISTRY}/timbre:${VERSION}-amd64 \
  --platform linux/amd64 \
  -f k8s/Dockerfile.app .

cat <<EOF

Building arm64 image...
EOF

docker build \
  --build-arg ARCH=arm64 \
  -t ${DOCKER_REGISTRY}/timbre:${VERSION}-arm64 \
  --platform linux/arm64 \
  -f k8s/Dockerfile.app .

cat <<EOF

Creating multi-architecture manifest...
EOF

docker manifest create \
  ${DOCKER_REGISTRY}/timbre:${VERSION} \
  --amend ${DOCKER_REGISTRY}/timbre:${VERSION}-amd64 \
  --amend ${DOCKER_REGISTRY}/timbre:${VERSION}-arm64

# Also tag as latest if not a dev version
if [[ "$VERSION" != *"-dev"* ]]; then
  cat <<EOF

Creating latest tag...
EOF

  docker manifest create \
    ${DOCKER_REGISTRY}/timbre:latest \
    --amend ${DOCKER_REGISTRY}/timbre:${VERSION}-amd64 \
    --amend ${DOCKER_REGISTRY}/timbre:${VERSION}-arm64
fi

# Push images if requested
if [ "$PUSH" = true ]; then
  cat <<EOF

Pushing images to registry...
EOF

  docker push ${DOCKER_REGISTRY}/timbre:${VERSION}-amd64
  docker push ${DOCKER_REGISTRY}/timbre:${VERSION}-arm64
  docker manifest push ${DOCKER_REGISTRY}/timbre:${VERSION}
  
  if [[ "$VERSION" != *"-dev"* ]]; then
    docker manifest push ${DOCKER_REGISTRY}/timbre:latest
  fi
fi

cat <<EOF

Build complete!
EOF 