#!/bin/bash

set -e  # Exit on error

echo "========================================="
echo "Starting install.sh test"
echo "========================================="

# Run install.sh
echo "Running install.sh..."
cd /home/testuser/shell

# Should test prerequisite installer and mise installer separately
echo "Running prerequisite installer..."
sudo bash -c "source /home/testuser/shell/internal/_install_prerequisite.sh && install_prerequisite"

echo "Running mise installer..."
bash -c "source /home/testuser/shell/internal/_install_mise.sh && install_mise"

echo ""
echo "========================================="
echo "Debugging .bashrc contents"
echo "========================================="
echo "Full contents of ~/.bashrc:"
cat ~/.bashrc
echo "========================================="
echo ""

echo "========================================="
echo "Verifying installation"
echo "========================================="

# Source the shell configuration to get PATH updates
source ~/.bashrc 2>/dev/null || source ~/.bash_profile 2>/dev/null || true

echo "Current PATH after sourcing .bashrc:"
echo "$PATH"
echo ""

# Test mise installation
echo -n "Checking mise... "
if /bin/bash -lc "~/.local/bin/mise --version" &>/dev/null; then
    MISE_VERSION=$(/bin/bash -lc "~/.local/bin/mise --version 2>&1 | tail -1")
    echo "✅ PASSED - $MISE_VERSION"
else
    echo "❌ FAILED - mise not found!"
    exit 1
fi

# Test ruby installation via mise
echo -n "Checking ruby... "
if /bin/bash -lc "~/.local/bin/mise exec -- ruby --version" &>/dev/null; then
    RUBY_VERSION=$(/bin/bash -lc "~/.local/bin/mise exec -- ruby --version" 2>&1)
    echo "✅ PASSED - $RUBY_VERSION"
else
    echo "❌ FAILED - ruby not found!"
    exit 1
fi

# Test that PATH contains mise
echo -n "Checking PATH contains mise... "
if /bin/bash -lc 'echo $PATH | grep -q ".local/bin"'; then
    echo "✅ PASSED"
else
    echo "❌ FAILED - mise not in PATH!"
    exit 1
fi

echo ""
echo "========================================="
echo "✅ mise and Ruby installed!!"
echo "========================================="
