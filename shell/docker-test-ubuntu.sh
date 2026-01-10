#!/bin/bash

CACHE_FLAG=""
if [ "$1" = "--no-cache" ]; then
  CACHE_FLAG="--no-cache"
fi

echo "Removing existing dotfiles:shell-ubuntu image"
docker rmi dotfiles:shell-ubuntu 2>/dev/null || true

docker build ${CACHE_FLAG:+$CACHE_FLAG} --progress plain -t dotfiles:shell-ubuntu -f shell/test/Dockerfile.ubuntu .
docker image inspect dotfiles:shell-ubuntu >/dev/null && echo "✅ Docker image build: dotfiles:shell-ubuntu" || (echo "❌ Docker image build failed"; exit 1)
