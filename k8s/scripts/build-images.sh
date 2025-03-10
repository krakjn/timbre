#!/bin/bash
set -e

DOCKER_REGISTRY=${DOCKER_REGISTRY:-"ghcr.io/krakjn"}
VERSION=$(cat pkg/version.txt | tr -d '[:space:]')
PUSH=${PUSH:-false}

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

export DOCKER_CLI_EXPERIMENTAL=enabled


echo "Building x86_64 (amd64) image..."
docker build \
  --build-arg ARCH=x86_64 \
  -t ${DOCKER_REGISTRY}/timbre:${VERSION}-amd64 \
  --platform linux/amd64 \
  -f k8s/Dockerfile.app .

echo "Building arm64 image..."
docker build \
  --build-arg ARCH=arm64 \
  -t ${DOCKER_REGISTRY}/timbre:${VERSION}-arm64 \
  --platform linux/arm64 \
  -f k8s/Dockerfile.app .

echo "Creating multi-architecture manifest..."
docker manifest create \
  ${DOCKER_REGISTRY}/timbre:${VERSION} \
  --amend ${DOCKER_REGISTRY}/timbre:${VERSION}-amd64 \
  --amend ${DOCKER_REGISTRY}/timbre:${VERSION}-arm64

if [[ "$VERSION" != *"-dev"* ]]; then
  echo "Creating latest tag..."
  docker manifest create \
    ${DOCKER_REGISTRY}/timbre:latest \
    ${DOCKER_REGISTRY}/timbre:${VERSION}-amd64 \
    ${DOCKER_REGISTRY}/timbre:${VERSION}-arm64
fi

if [ "$PUSH" = true ]; then
  echo "Pushing images to registry..."

  docker push ${DOCKER_REGISTRY}/timbre:${VERSION}-amd64
  docker push ${DOCKER_REGISTRY}/timbre:${VERSION}-arm64
  docker manifest push ${DOCKER_REGISTRY}/timbre:${VERSION}
  
  if [[ "$VERSION" != *"-dev"* ]]; then
    docker manifest push ${DOCKER_REGISTRY}/timbre:latest
  fi
fi