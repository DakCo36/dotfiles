#!/usr/bin/env bats
TEST_UTILS_SCRIPT_DIR_PATH="$(dirname ${BASH_SOURCE[0]})"
UTILS_SCRIPT_PATH="${TEST_UTILS_SCRIPT_DIR_PATH}/../../lib/utils.sh"

source $UTILS_SCRIPT_PATH

set_up_before_script() {
  export ORIGINAL_PATH="$PATH"

  # Mocking logging functions
  export ORIGINAL_LOG_INFO="$(declare -f log_info)"
  export ORIGINAL_LOG_ERROR="$(declare -f log_error)"

  log_info() { :; }
  log_error() { :; } 
}

tear_down_after_script() {
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

set_up() {
  export TEST_DIR=$(mktemp -d)
  export TEST_LOG=$TEST_DIR/test.log
  export TEST_BIN_DIR="$TEST_DIR/bin"

  mkdir -p "$TEST_BIN_DIR"

  export ORIGINAL_PATH="$PATH"
  export PATH="$TEST_BIN_DIR:$PATH"
}

tear_down() {
  if [[ -d "$TEST_DIR" ]]; then
    rm -rf "$TEST_DIR"
  fi
  export PATH="$ORIGINAL_PATH"
}

function test_has_sudo_previleges_success() {
  # Mocking sudo command to simulate success
  cat > "$TEST_DIR/bin/sudo" << 'EOF'
#!/bin/bash
if [[ "$1" == "-v" ]]; then
  exit 0
else
  exec $(which -a sudo | grep -v "$BATS_TMPDIR" | head -1) "$@"
fi
EOF
  chmod +x "$TEST_DIR/bin/sudo"

  # When
  has_sudo_privileges
  
  # Then
  exit_code=$?
  assert_true $exit_code
}

function test_has_sudo_previleges_failure() {
  # Mocking sudo command to simulate failure
  cat > "$TEST_DIR/bin/sudo" << 'EOF'
#!/bin/bash
if [[ "$1" == "-v" ]]; then
  exit 1
else
  exec $(which -a sudo | grep -v "$BATS_TMPDIR" | head -1) "$@"
fi
EOF
  chmod +x "$TEST_DIR/bin/sudo"

  # When
  has_sudo_privileges
  
  # Then
  exit_code=$?
  assert_false $exit_code
}

function test_restore_trap() {
  local trap_type="ERR"
  local original_trap="trap 'echo \"Test\"' ERR"

  # When
  trap 'echo "Not this trap"' ERR
  restore_trap "$trap_type" "$original_trap"

  # Then
  current_trap=$(trap -p ERR)
  assert_same "trap -- 'echo \"Test\"' ERR" "$current_trap"
}

function test_restore_empty_trap() {
  local trap_type="ERR"

  # When
  trap 'echo "Not this trap"' $trap_type
  restore_trap "$trap_type" ""

  # Then
  current_trap=$(trap -p ERR)
  assert_true $?
  assert_same "trap -- ':' $trap_type" "$current_trap"
}
