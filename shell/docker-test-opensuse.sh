#!/bin/bash

CACHE_FLAG=""
if [ "$1" = "--no-cache" ]; then
  CACHE_FLAG="--no-cache"
fi

echo "Removing existing dotfiles:shell-opensuse image"
docker rmi dotfiles:shell-opensuse 2>/dev/null || true

docker build ${CACHE_FLAG:+$CACHE_FLAG} --progress plain -t dotfiles:shell-opensuse -f shell/test/Dockerfile.opensuse .
docker image inspect dotfiles:shell-opensuse >/dev/null && echo "✅ Docker image build: dotfiles:shell-opensuse" || (echo "❌ Docker image build failed"; exit 1)
