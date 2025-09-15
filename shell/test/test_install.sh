#!/bin/bash

set -e  # Exit on error

echo "========================================="
echo "Starting install.sh test"
echo "========================================="

# Run install.sh
echo "Running install.sh..."
cd /home/testuser/shell && ./install.sh

echo ""
echo "========================================="
echo "Verifying installation"
echo "========================================="

# Source the shell configuration to get PATH updates
source ~/.bashrc 2>/dev/null || source ~/.bash_profile 2>/dev/null || true

# Test rbenv installation
echo -n "Checking rbenv... "
if /bin/bash -lc "rbenv --version" &>/dev/null; then
    RBENV_VERSION=$(/bin/bash -lc "rbenv --version" 2>&1)
    echo "✅ PASSED - $RBENV_VERSION"
else
    echo "❌ FAILED - rbenv not found!"
    exit 1
fi

# Test ruby installation
echo -n "Checking ruby... "
if /bin/bash -lc "ruby --version" &>/dev/null; then
    RUBY_VERSION=$(/bin/bash -lc "ruby --version" 2>&1)
    echo "✅ PASSED - $RUBY_VERSION"
else
    echo "❌ FAILED - ruby not found!"
    exit 1
fi

# Test that PATH is properly set
echo -n "Checking PATH contains rbenv... "
if /bin/bash -lc 'echo $PATH | grep -q rbenv'; then
    echo "✅ PASSED"
else
    echo "❌ FAILED - rbenv not in PATH!"
    exit 1
fi

echo ""
echo "========================================="
echo "✅ Ruby installed!!"
echo "========================================="
