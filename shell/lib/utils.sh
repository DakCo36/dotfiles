#!/bin/bash

if [[ -n "${BASH_SOURCE[0]}" ]]; then
  UTILS_SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
else
  UTILS_SCRIPT_DIR="$(pwd)"
fi
LOGGER_FILE="$UTILS_SCRIPT_DIR/logger.sh"

source "${LOGGER_FILE}" || return 1
log_info "Loading ${LOGGER_FILE} successfully"

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

  if [[ -n "$original_trap" ]]; then
    eval "$original_trap"
  else
    eval "trap - $trap_type"
  fi
}

function handle_error() {
  local exit_code=$1
  local line_number=${2:-unknown}
  
  log_error "An error occured in _install_prerequisite.sh at line $line_number"
  log_error "Exit code: $exit_code"

  exit $exit_code
}
