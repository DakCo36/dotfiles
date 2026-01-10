#!/bin/bash

CACHE_FLAG=""
if [ "$1" = "--no-cache" ]; then
  CACHE_FLAG="--no-cache"
fi

echo "Removing existing dotfiles:shell-rocky image"
docker rmi dotfiles:shell-rocky 2>/dev/null || true

docker build ${CACHE_FLAG:+$CACHE_FLAG} --progress plain -t dotfiles:shell-rocky -f shell/test/Dockerfile.rocky .
docker image inspect dotfiles:shell-rocky >/dev/null && echo "✅ Docker image build: dotfiles:shell-rocky" || (echo "❌ Docker image build failed"; exit 1)
