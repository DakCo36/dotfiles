#!/usr/bin/env bash

# Each internal script manages its own shell options

# Display a simple help message
function show_help() {
  cat <<EOF
Usage: $0 [--help]

Install prerequisites and Ruby using internal scripts.
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse arguments
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  show_help
  exit 0
fi

# Source internal scripts
source "$SCRIPT_DIR/internal/_install_prerequisite.sh" || {
  echo "Failed to load Prerequisite Installer ($SCRIPT_DIR/internal/_install_prerequisite.sh)" >&2
  exit 1
}
source "$SCRIPT_DIR/internal/_install_ruby.sh" || {
  echo "Failed to load Ruby Installer ($SCRIPT_DIR/internal/_install_ruby.sh)" >&2
  exit 1
}

# Run the installers
install_prerequisite
install_ruby

exit 0
