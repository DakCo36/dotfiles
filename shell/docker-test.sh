#!/bin/bash

CACHE_FLAG=""
if [ "$1" = "--no-cache" ]; then
  CACHE_FLAG="--no-cache"
fi

echo "Removing existing dotfiles:shell image"
docker rmi dotfiles:shell 2>/dev/null || true

docker build ${CACHE_FLAG:+$CACHE_FLAG} --progress plain -t dotfiles:shell -f test/Dockerfile .
docker image inspect dotfiles:shell >/dev/null && echo "✅ Docker image build: dotfiles:shell" || (echo "❌ Docker image build failed"; exit 1)

