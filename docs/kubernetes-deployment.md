# Deploying Timbre to Kubernetes

This document provides instructions for deploying Timbre to a Kubernetes cluster, leveraging the project's cross-compilation capabilities.

## Prerequisites

- Docker installed with buildx and multi-architecture support
- kubectl installed
- Access to a Kubernetes cluster
- GitHub account with permissions to the repository

## Setting Up a Local Kubernetes Cluster

If you don't have a Kubernetes cluster, you can set up a local one using kind (Kubernetes IN Docker).

```bash
# Run the setup script
chmod +x scripts/setup-cluster.sh
./scripts/setup-cluster.sh
```

This script will:
1. Install kind and kubectl if they're not already installed
2. Create a Kubernetes cluster with one control plane node and one worker node
3. Configure port forwarding from host port 30000 to container port 30000

## Building Multi-Architecture Docker Images

Timbre supports both x86_64 and arm64 architectures. You can build Docker images for both architectures using the provided script:

```bash
# Build Docker images
chmod +x scripts/build-images.sh
./scripts/build-images.sh --registry ghcr.io/krakjn

# To also push the images
./scripts/build-images.sh --registry ghcr.io/krakjn --push
```

This script will:
1. Build separate Docker images for x86_64 and arm64 architectures
2. Create a multi-architecture manifest that combines both images
3. Optionally push the images and manifest to the specified registry

> **Note:** Docker experimental features must be enabled for manifest support. The script will handle this automatically.

## Deploying to Kubernetes

You can deploy Timbre to Kubernetes using the deployment script:

```bash
# Deploy to Kubernetes
chmod +x scripts/deploy.sh
./scripts/deploy.sh --registry ghcr.io/krakjn --version $(cat pkg/version.txt)

# To deploy to a different namespace
./scripts/deploy.sh --registry ghcr.io/krakjn --version $(cat pkg/version.txt) --namespace my-namespace
```

This script will:
1. Create the namespace if it doesn't exist
2. Apply all Kubernetes manifests in the `k8s/` directory
3. Wait for the deployment to be ready
4. Show the pod status and logs

## Kubernetes Manifests

The Kubernetes manifests are located in the `k8s/` directory:

- `namespace.yaml`: Defines the Timbre namespace
- `deployment.yaml`: Defines the Timbre deployment with proper resource limits and probes
- `service.yaml`: Exposes the Timbre service on port 30000
- `configmap.yaml`: Contains the Timbre configuration in TOML format

## CI/CD Pipeline

The CI/CD pipeline is configured in `.github/workflows/ci-cd.yml`. It consists of two jobs:

1. `build`: Builds and pushes multi-architecture Docker images
2. `deploy`: Deploys the images to Kubernetes

The pipeline automatically:
- Builds images for both x86_64 and arm64 architectures
- Creates a multi-architecture manifest
- Deploys to Kubernetes when changes are pushed to the main branch
- Verifies the deployment is successful

## Version Handling

Timbre uses semantic versioning with optional development suffixes:

- Release versions: `X.Y.Z` (e.g., `1.2.3`)
- Development versions: `X.Y.Z-dev_<sha>` (e.g., `1.2.3-dev_abcd1234`)

The CI/CD pipeline automatically:
- Tags Docker images with the version from `pkg/version.txt`
- Only tags as `latest` for release versions (without `-dev` suffix)
- Includes the version in Kubernetes deployment labels

## Accessing the Application

After deployment, you can access the application at:

```
http://localhost:30000
```

If you're using a remote cluster, replace `localhost` with the appropriate hostname or IP address.

## Validating the Deployment

You can validate the deployment using the following commands:

```bash
# Check if the pods are running
kubectl get pods -n timbre -l app=timbre

# Check the logs
kubectl logs -n timbre -l app=timbre

# Check the service
kubectl get service timbre -n timbre

# Test the application
curl http://localhost:30000/version
```

## Troubleshooting

If you encounter issues with the deployment, check the following:

1. Pod status:
   ```bash
   kubectl describe pod -n timbre -l app=timbre
   ```

2. Pod logs:
   ```bash
   kubectl logs -n timbre -l app=timbre
   ```

3. Service status:
   ```bash
   kubectl describe service timbre -n timbre
   ```

4. Events:
   ```bash
   kubectl get events -n timbre --sort-by='.lastTimestamp'
   ```

## Security Considerations

The deployment follows security best practices:
- Running as a non-root user
- Using resource limits to prevent resource exhaustion
- Storing configuration in ConfigMaps
- Using readiness and liveness probes for health checking 