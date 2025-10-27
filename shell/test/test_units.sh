#!/bin/bash

set -e  # Exit on error

echo "========================================="
echo "Running unit tests"
echo "========================================="

# Install bats for testing
echo "Installing bats testing framework..."
cd /home/testuser/shell/test

# Install bats helper libraries if not present
echo "Setting up bats helper libraries..."
if [ ! -f test_helper/bats-support/load.bash ]; then
    cd test_helper/bats-support
    git clone https://github.com/bats-core/bats-support.git . --depth 1 >/dev/null 2>&1
    cd ../..
fi
if [ ! -f test_helper/bats-assert/load.bash ]; then
    cd test_helper/bats-assert
    git clone https://github.com/bats-core/bats-assert.git . --depth 1 >/dev/null 2>&1
    cd ../..
fi

# Run lib tests
echo ""
echo "Running lib tests..."
for test_file in lib/*.bats; do
    if [ -f "$test_file" ]; then
        echo "  Testing: $(basename $test_file)"
        bats "$test_file"
    fi
done

# Run internal tests
echo ""
echo "Running internal tests..."
for test_file in internal/*.bats; do
    if [ -f "$test_file" ]; then
        echo "  Testing: $(basename $test_file)"
        bats "$test_file"
    fi
done

echo ""
echo "✅ All unit tests passed!"
