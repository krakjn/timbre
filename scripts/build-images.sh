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

echo "Building Timbre Docker images version $VERSION"
echo "Docker Registry: $DOCKER_REGISTRY"
echo "Push: $PUSH"

# Build x86_64 image
echo "Building x86_64 image..."
docker build \
  --build-arg ARCH=x86_64 \
  -t ${DOCKER_REGISTRY}/timbre:${VERSION}-amd64 \
  -f Dockerfile.app .

# Build arm64 image
echo "Building arm64 image..."
docker build \
  --build-arg ARCH=arm64 \
  -t ${DOCKER_REGISTRY}/timbre:${VERSION}-arm64 \
  -f Dockerfile.app .

# Create manifest for multi-arch image
echo "Creating multi-arch manifest..."
docker manifest create \
  ${DOCKER_REGISTRY}/timbre:${VERSION} \
  --amend ${DOCKER_REGISTRY}/timbre:${VERSION}-amd64 \
  --amend ${DOCKER_REGISTRY}/timbre:${VERSION}-arm64

# Also tag as latest if requested
if [[ "$VERSION" != *"-dev"* ]]; then
  echo "Creating latest tag..."
  docker manifest create \
    ${DOCKER_REGISTRY}/timbre:latest \
    --amend ${DOCKER_REGISTRY}/timbre:${VERSION}-amd64 \
    --amend ${DOCKER_REGISTRY}/timbre:${VERSION}-arm64
fi

# Push images if requested
if [ "$PUSH" = true ]; then
  echo "Pushing images..."
  docker push ${DOCKER_REGISTRY}/timbre:${VERSION}-amd64
  docker push ${DOCKER_REGISTRY}/timbre:${VERSION}-arm64
  docker manifest push ${DOCKER_REGISTRY}/timbre:${VERSION}
  
  if [[ "$VERSION" != *"-dev"* ]]; then
    docker manifest push ${DOCKER_REGISTRY}/timbre:latest
  fi
fi

echo "Build complete!" 