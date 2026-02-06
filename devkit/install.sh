#!/usr/bin/env bash
# Devkit install script - wrapper for Ruby CLI
# Usage: ./install.sh [options] [component...]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo ">>> Installing Ruby dependencies..."
bundle install --quiet

echo ">>> Running devkit CLI..."
bundle exec ruby bin/cli.rb install "$@"
