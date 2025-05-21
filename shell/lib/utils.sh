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
