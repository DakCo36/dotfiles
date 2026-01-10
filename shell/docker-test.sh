#!/bin/bash

function show_help() {
  cat <<EOF
Usage: $0 [ubuntu|rocky|opensuse] [--no-cache]

Run Docker tests for the specified distribution.
If no distribution is specified, runs tests for all supported distributions.
EOF
}

TARGET=$1
CACHE_FLAG=""

if [[ "$1" == "--no-cache" ]]; then
  TARGET=""
  CACHE_FLAG="--no-cache"
elif [[ "$2" == "--no-cache" ]]; then
  CACHE_FLAG="--no-cache"
fi

case "$TARGET" in
  ubuntu)
    ./shell/docker-test-ubuntu.sh $CACHE_FLAG
    ;;
  rocky)
    ./shell/docker-test-rocky.sh $CACHE_FLAG
    ;;
  opensuse)
    ./shell/docker-test-opensuse.sh $CACHE_FLAG
    ;;
  help|--help|-h)
    show_help
    exit 0
    ;;
  *)
    if [[ -z "$TARGET" || "$TARGET" == "--no-cache" ]]; then
      echo "Running tests for all distributions..."
      ./shell/docker-test-ubuntu.sh $CACHE_FLAG
      ./shell/docker-test-rocky.sh $CACHE_FLAG
      ./shell/docker-test-opensuse.sh $CACHE_FLAG
    else
      echo "Unknown target: $TARGET"
      show_help
      exit 1
    fi
    ;;
esac
