#!/bin/bash

UTILS_SCRIPT_DIR="$(dirname ${BASH_SOURCE[0]})"
source "$UTILS_SCRIPT_DIR/logger.sh"

function has_sudo_privileges() {
  if sudo -v &>/dev/null; then
    log_info "Sudo privileges are available."
    return 0
  else
    log_error "Sudo privileges are required to run this script."
    return 1
  fi
}

function restore_trap() {
  local trap_type="$1"
  local original_trap="$2"

  if [[ -z "$original_trap" ]]; then
    # Unknown why 'trap - $trap_type' doesn't work
    eval "trap -- ":" $trap_type"
  else
    eval "$original_trap"
  fi

  return 0
}

function handle_error() {
  local exit_code=$1
  local line_number=${2:-unknown}
  
  log_error "An error occured in _install_prerequisite.sh at line $line_number"
  log_error "Exit code: $exit_code"

  exit $exit_code
}
