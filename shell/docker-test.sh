#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

usage() {
  cat <<'USAGE'
Usage: ./docker-test.sh [--all | <distro> [<distro> ...]]

Options:
  --all        Build images for all available distributions.
  <distro>     One or more distro names matching docker-test/<distro>.Dockerfile.

Examples:
  ./docker-test.sh ubuntu
  ./docker-test.sh rocky opensuse
  ./docker-test.sh --all
USAGE
}

mapfile -t available_distros < <(for f in docker-test/*.Dockerfile; do basename "$f" .Dockerfile; done)

if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

declare -A requested

for arg in "$@"; do
  if [[ $arg == "--all" ]]; then
    for distro in "${available_distros[@]}"; do
      requested[$distro]=1
    done
    continue
  fi

  if [[ -f "docker-test/${arg}.Dockerfile" ]]; then
    requested[$arg]=1
  else
    echo "Unknown distro: ${arg}" >&2
    usage
    exit 1
  fi
done

if [[ ${#requested[@]} -eq 0 ]]; then
  echo "No distributions selected." >&2
  usage
  exit 1
fi

mapfile -t selected_distros < <(printf '%s\n' "${!requested[@]}" | sort)

for distro in "${selected_distros[@]}"; do
  dockerfile="docker-test/${distro}.Dockerfile"
  tag="dotfiles:shell-${distro}"
  echo "Building ${tag}..."
  docker build --progress plain -t "$tag" -f "$dockerfile" .
  docker image inspect "$tag" >/dev/null && echo "✅ Docker image build: $tag"
  echo
done
