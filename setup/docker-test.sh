#!/bin/bash

CACHE_FLAG=""
if [ "$1" = "--no-cache" ]; then
  CACHE_FLAG="--no-cache"
fi

IMAGE="${IMAGE:-dotfiles:setup}"

echo "Removing existing $IMAGE image"
docker rmi "$IMAGE" 2>/dev/null || true

docker build ${CACHE_FLAG:+$CACHE_FLAG} --progress plain -t "$IMAGE" -f test/Dockerfile .
docker image inspect "$IMAGE" >/dev/null && echo "✅ Docker image build: $IMAGE" || (echo "❌ Docker image build failed"; exit 1)

