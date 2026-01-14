#!/bin/bash

# Build and push all image variants for the demo
# Usage: ./build-images.sh

REPO="rahees9983/rollouts-demo-app"

cd "$(dirname "$0")/app"

echo "=========================================="
echo "Building v1-stable (healthy baseline)"
echo "=========================================="
docker buildx build --platform linux/amd64,linux/arm64 \
  --build-arg APP_VERSION=v1 \
  --build-arg ERROR_RATE=0 \
  --build-arg LATENCY=0 \
  -t ${REPO}:v1-stable \
  --push .

echo "=========================================="
echo "Building v2-stable (healthy new version)"
echo "=========================================="
docker buildx build --platform linux/amd64,linux/arm64 \
  --build-arg APP_VERSION=v2 \
  --build-arg ERROR_RATE=0 \
  --build-arg LATENCY=0 \
  -t ${REPO}:v2-stable \
  --push .

echo "=========================================="
echo "Building v2-buggy (50% error rate)"
echo "=========================================="
docker buildx build --platform linux/amd64,linux/arm64 \
  --build-arg APP_VERSION=v2 \
  --build-arg ERROR_RATE=0.5 \
  --build-arg LATENCY=0 \
  -t ${REPO}:v2-buggy \
  --push .

echo "=========================================="
echo "Building v2-slow (2 second latency)"
echo "=========================================="
docker buildx build --platform linux/amd64,linux/arm64 \
  --build-arg APP_VERSION=v2 \
  --build-arg ERROR_RATE=0 \
  --build-arg LATENCY=2 \
  -t ${REPO}:v2-slow \
  --push .

echo "=========================================="
echo "Building v2-flaky (10% errors, slight latency)"
echo "=========================================="
docker buildx build --platform linux/amd64,linux/arm64 \
  --build-arg APP_VERSION=v2 \
  --build-arg ERROR_RATE=0.1 \
  --build-arg LATENCY=0.2 \
  -t ${REPO}:v2-flaky \
  --push .

echo "=========================================="
echo "All images built and pushed!"
echo "=========================================="
echo ""
echo "Available images:"
echo "  ${REPO}:v1-stable  - Healthy baseline"
echo "  ${REPO}:v2-stable  - Healthy new version (SUCCESS scenario)"
echo "  ${REPO}:v2-buggy   - 50% errors (ROLLBACK scenario)"
echo "  ${REPO}:v2-slow    - 2s latency (ROLLBACK scenario)"
echo "  ${REPO}:v2-flaky   - 10% errors (MIGHT rollback)"
