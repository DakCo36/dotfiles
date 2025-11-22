#!/usr/bin/env bash

CACHE_FLAG=""
if [ "$1" = "--no-cache" ]; then
  CACHE_FLAG="--no-cache"
fi

echo "Removing existing dotfiles:ruby image"
docker rmi dotfiles:ruby 2>/dev/null || true

docker build ${CACHE_FLAG:+$CACHE_FLAG} --progress plain -t dotfiles:ruby -f ./bin/test/Dockerfile .
