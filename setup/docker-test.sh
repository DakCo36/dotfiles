#!/bin/bash

CACHE_FLAG=""
if [ "$1" = "--no-cache" ]; then
  CACHE_FLAG="--no-cache"
fi

echo "Removing existing dotfiles:setup image"
docker rmi dotfiles:setup 2>/dev/null || true

docker build ${CACHE_FLAG:+$CACHE_FLAG} --progress plain -t dotfiles:setup -f test/Dockerfile .
docker image inspect dotfiles:setup >/dev/null && echo "✅ Docker image build: dotfiles:setup" || (echo "❌ Docker image build failed"; exit 1)

