#!/usr/bin/env bats
BATS_DIR="$(dirname ${BATS_TEST_FILENAME})"
BATS_TMPDIR="$(mktemp -d)"
source ${BATS_DIR}/../../lib/utils.sh
load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'

setup() {
  export ORIGINAL_PATH="$PATH"
  mkdir -p "$BATS_TMPDIR/bin"
  export PATH="$BATS_TMPDIR/bin:$PATH"

  # Mocking logging functions
  export ORIGINAL_LOG_INFO="$(declare -f log_info)"
  export ORIGINAL_LOG_ERROR="$(declare -f log_error)"

  log_info() { :; }
  log_error() { :; } 
}

teardown() {
  export PATH="$ORIGINAL_PATH"
  
  if [ -n "$ORIGINAL_LOG_INFO" ]; then
    eval "$ORIGINAL_LOG_INFO"
    unset ORIGINAL_LOG_INFO
  fi
  if [ -n "$ORIGINAL_LOG_ERROR" ]; then
    eval "$ORIGINAL_LOG_ERROR"
    unset ORIGINAL_LOG_ERROR
  fi
}

@test "has_sudo_privileges returns 0 when sudo is available" {
  # Mocking sudo command to simulate success
  # Given
  cat > "$BATS_TMPDIR/bin/sudo" << 'EOF'
#!/bin/bash
if [[ "$1" == "-v" ]]; then
  exit 0
else
  exec $(which -a sudo | grep -v "$BATS_TMPDIR" | head -1) "$@"
fi
EOF
  chmod +x "$BATS_TMPDIR/bin/sudo"
  
  # When
  run has_sudo_privileges
  
  # Then
  assert_success
}

@test "has_sudo_privileges returns 1 when sudo is not available" {
  # Mocking sudo command to simulate failure
  # Given
  cat > "$BATS_TMPDIR/bin/sudo" << 'EOF'
#!/bin/bash
if [[ "$1" == "-v" ]]; then
  exit 1
else
  exec $(which -a sudo | grep -v "$BATS_TMPDIR" | head -1) "$@"
fi
EOF
  chmod +x "$BATS_TMPDIR/bin/sudo"
  
  # When
  run has_sudo_privileges
  
  # Then
  assert_failure
}

@test "restore_trap restore the trap successfully" {
  # Given
  local trap_type="ERR"
  local original_trap="trap 'echo \"Test\"' ERR"

  # When
  trap 'echo "Not this trap"' ERR
  restore_trap "$trap_type" "$original_trap"

  # Then
  run trap -p ERR
  assert_success
  assert_output "trap -- 'echo \"Test\"' ERR"
}

@test "restore_trap restore empty trap when original_trap is empty" {
  # Given
  local trap_type="ERR"

  # When
  trap 'echo "Not this trap"' ERR
  restore_trap "$trap_type"

  # Then
  run trap -p ERR
  assert_success
  assert_output ""
}
