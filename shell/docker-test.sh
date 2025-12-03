#!/bin/bash

docker rmi dotfiles:shell 2>/dev/null || true

docker build --progress plain -t dotfiles:shell -f test/Dockerfile .
docker image inspect dotfiles:shell >/dev/null && echo "✅ Docker image build: dotfiles:shell" || (echo "❌ Docker image build failed"; exit 1)

