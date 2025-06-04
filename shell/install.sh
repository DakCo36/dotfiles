#!/bin/bash

# Each internal script manages its own shell options

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source internal scripts
source "$SCRIPT_DIR/internal/_install_prerequisite.sh" || {
  echo "Failed to load prerequisite installer" >&2
  exit 1
}
source "$SCRIPT_DIR/internal/_install_ruby.sh" || {
  echo "Failed to load ruby installer" >&2
  exit 1
}

# Run the installers
install_prerequisite
install_ruby

