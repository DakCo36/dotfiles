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

function run_test() {
  local distro=$1
  local dockerfile="shell/test/Dockerfile.${distro}"
  local image_name="dotfiles:shell-${distro}"

  if [[ ! -f "$dockerfile" ]]; then
    echo "Error: Dockerfile not found at $dockerfile"
    return 1
  fi

  echo "Removing existing $image_name image"
  docker rmi "$image_name" 2>/dev/null || true

  echo "Building and testing $distro..."
  # Use DOCKER_BUILDKIT=1 for better build performance and output
  DOCKER_BUILDKIT=1 docker build ${CACHE_FLAG:+$CACHE_FLAG} --progress plain -t "$image_name" -f "$dockerfile" .

  if docker image inspect "$image_name" >/dev/null 2>&1; then
    echo "✅ Docker image build: $image_name"
  else
    echo "❌ Docker image build failed for $distro"
    return 1
  fi
}

case "$TARGET" in
  ubuntu|rocky|opensuse)
    run_test "$TARGET"
    ;;
  help|--help|-h)
    show_help
    exit 0
    ;;
  *)
    if [[ -z "$TARGET" || "$TARGET" == "--no-cache" ]]; then
      echo "Running tests for all distributions..."
      failures=0
      run_test "ubuntu" || ((failures++))
      run_test "rocky" || ((failures++))
      run_test "opensuse" || ((failures++))

      if [[ $failures -eq 0 ]]; then
        echo "All tests passed successfully."
      else
        echo "$failures distribution(s) failed."
        exit 1
      fi
    else
      echo "Unknown target: $TARGET"
      show_help
      exit 1
    fi
    ;;
esac
