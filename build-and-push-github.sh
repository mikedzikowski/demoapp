#!/bin/bash

# ASPM Demo - GitHub Container Registry Build and Push Script
# This script builds the images and pushes them to GitHub Container Registry (ghcr.io)

set -e

# Configuration
GITHUB_USERNAME="mikedzikowski"
GITHUB_REPO="demoapp"
REGISTRY="ghcr.io"
IMAGE_PREFIX="${REGISTRY}/${GITHUB_USERNAME}/${GITHUB_REPO}"

echo "🚀 Building and pushing ASPM Demo images to GitHub Container Registry"
echo "========================================================================"
echo "Registry: $REGISTRY"
echo "Image prefix: $IMAGE_PREFIX"
echo ""

# Check if logged into GitHub Container Registry
echo "🔐 Checking GitHub Container Registry authentication..."
if ! echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_USERNAME" --password-stdin 2>/dev/null; then
    echo "❌ Not authenticated with GitHub Container Registry"
    echo ""
    echo "Please authenticate using one of these methods:"
    echo ""
    echo "Method 1 - Personal Access Token:"
    echo "  1. Create a PAT with 'packages:write' scope at: https://github.com/settings/tokens"
    echo "  2. Run: echo 'YOUR_TOKEN' | docker login ghcr.io -u $GITHUB_USERNAME --password-stdin"
    echo ""
    echo "Method 2 - Environment Variable:"
    echo "  1. export GITHUB_TOKEN=your_pat_token"
    echo "  2. Re-run this script"
    echo ""
    exit 1
fi

echo "✅ Successfully authenticated with GitHub Container Registry"
echo ""

# Build and tag images
echo "🏗️  Building images..."

# Frontend Image
echo "Building frontend image..."
if docker build -t $IMAGE_PREFIX/aspm-demo-frontend:latest ../frontend; then
    echo "✅ Frontend image built successfully"
else
    echo "❌ Frontend image build failed"
    exit 1
fi

# Backend Image
echo "Building backend image..."
if docker build -t $IMAGE_PREFIX/aspm-demo-backend:latest ../backend; then
    echo "✅ Backend image built successfully"
else
    echo "❌ Backend image build failed"
    exit 1
fi

echo ""
echo "📤 Pushing images to GitHub Container Registry..."

# Push Frontend
echo "Pushing frontend image..."
if docker push $IMAGE_PREFIX/aspm-demo-frontend:latest; then
    echo "✅ Frontend image pushed successfully"
else
    echo "❌ Frontend image push failed"
    exit 1
fi

# Push Backend
echo "Pushing backend image..."
if docker push $IMAGE_PREFIX/aspm-demo-backend:latest; then
    echo "✅ Backend image pushed successfully"
else
    echo "❌ Backend image push failed"
    exit 1
fi

echo ""
echo "🎉 All images successfully built and pushed!"
echo ""
echo "📦 Images available at:"
echo "  • Frontend: $IMAGE_PREFIX/aspm-demo-frontend:latest"
echo "  • Backend:  $IMAGE_PREFIX/aspm-demo-backend:latest"
echo ""
echo "🔍 View packages at: https://github.com/$GITHUB_USERNAME?tab=packages"
echo ""
echo "🚀 Next steps:"
echo "  1. Update OpenShift manifests to use these images"
echo "  2. Deploy to OpenShift using the deployment script"
echo ""