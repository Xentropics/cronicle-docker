#!/bin/bash
set -e

# Docker Image Publishing Script
# Builds and pushes multi-architecture Docker images

IMAGE_NAME="xentropics/cronicle"
VERSION="1.0.0"

echo "========================================="
echo "Docker Image Publishing Script"
echo "========================================="
echo "Image: $IMAGE_NAME"
echo "Version: $VERSION"
echo "========================================="

# Check if logged in to Docker Hub
if ! docker info | grep -q "Username"; then
    echo "Please login to Docker Hub first:"
    docker login
fi

# Build for current platform (testing)
echo ""
echo "Building image for local platform..."
docker build -t ${IMAGE_NAME}:${VERSION} -t ${IMAGE_NAME}:latest .

echo ""
echo "Testing image..."
docker run --rm ${IMAGE_NAME}:latest node --version

# Ask if user wants to push
echo ""
read -p "Push to Docker Hub? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Setup buildx for multi-arch
    echo ""
    echo "Setting up buildx for multi-architecture build..."
    docker buildx create --name multiarch --use 2>/dev/null || docker buildx use multiarch
    docker buildx inspect --bootstrap
    
    # Build and push multi-arch
    echo ""
    echo "Building and pushing multi-architecture images..."
    docker buildx build \
        --platform linux/amd64,linux/arm64 \
        -t ${IMAGE_NAME}:${VERSION} \
        -t ${IMAGE_NAME}:1.0 \
        -t ${IMAGE_NAME}:1 \
        -t ${IMAGE_NAME}:latest \
        --push \
        .
    
    echo ""
    echo "========================================="
    echo "✓ Images pushed successfully!"
    echo "========================================="
    echo "Tags:"
    echo "  - ${IMAGE_NAME}:latest"
    echo "  - ${IMAGE_NAME}:${VERSION}"
    echo "  - ${IMAGE_NAME}:1.0"
    echo "  - ${IMAGE_NAME}:1"
    echo ""
    echo "View at: https://hub.docker.com/r/${IMAGE_NAME}"
else
    echo "Skipping push. Images built locally:"
    echo "  - ${IMAGE_NAME}:latest"
    echo "  - ${IMAGE_NAME}:${VERSION}"
fi

echo ""
echo "Next steps:"
echo "1. Push to GitHub: git push origin master && git push origin v${VERSION}"
echo "2. Create GitHub release at: https://github.com/YOUR_USERNAME/xentropics-cronicle/releases/new"
echo "3. Update Docker Hub description with README content"
