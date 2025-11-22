#!/usr/bin/env bash

CACHE_FLAG=""
if [ "$1" = "--no-cache" ]; then
  CACHE_FLAG="--no-cache"
fi

docker build ${CACHE_FLAG:+$CACHE_FLAG} --progress plain -t dotfiles:ruby -f ./bin/test/Dockerfile .
