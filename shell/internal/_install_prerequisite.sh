#!/bin/bash

if [[ -n "${BASH_SOURCE[0]}" ]]; then
  INSTALL_PREREQUISITE_SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
else
  INSTALL_PREREQUISITE_SCRIPT_DIR="$(pwd)"
fi
source "$INSTALL_PREREQUISITE_SCRIPT_DIR/../lib/utils.sh" || return 1
source "$INSTALL_PREREQUISITE_SCRIPT_DIR/../lib/logger.sh" || return 1
INSTALL_LOG=$(mktemp /tmp/install_prerequisite.XXXXXX.log)

UBUNTU_PACKAGES=(
  "build-essential"
  "libssl-dev"
  "libreadline-dev"
  "libyaml-dev"
  "libgmp-dev"
  "zlib1g-dev"
  "libncurses5-dev"
  "libffi-dev"
  "libgdbm-dev"
  "autoconf"
  "bison"
)

function install_ubuntu_prerequisite() {
  log_info "Updateing package list..."
  sudo apt-get update &>> "$INSTALL_LOG"

  log_info "Installing Ubuntu prerequisites..."
  for package in "${UBUNTU_PACKAGES[@]}"; do
    if ! dpkg -s "${package}" &>/dev/null; then
      log_info "Installing $package..."
      sudo apt-get install -y "$package" &>> "$INSTALL_LOG"
    else
      log_info "$package is already installed."
    fi
  done
}

function install_prerequisite() {
  local ORIGINAL_SHELL_OPTIONS=$(set +o)
  local ORIGINAL_TRAP_EXIT="$(trap -p EXIT || echo '')"
  local ORIGINAL_TRAP_ERR="$(trap -p ERR || echo '')"
  set -euo pipefail

  trap 'handle_error $? "$LINENO"' ERR
  trap 'cleanup $? "${ORIGINAL_SHELL_OPTIONS}" "${ORIGINAL_TRAP_EXIT}" "${ORIGINAL_TRAP_ERR}"' EXIT

  log_info "Detail logs are in: $INSTALL_LOG"
  if ! has_sudo_privileges; then
    log_error "Need sudo privileges to install prerequisites."
    false
  fi

  if [[ -f "/etc/os-release" ]]; then
    . /etc/os-release
  fi

  if [[ "$ID" == "ubuntu" ]]; then
    install_ubuntu_prerequisite
  else
    log_error "Unsupported OS: $ID"
    return 1
  fi

  cleanup()
  return 0
}

function cleanup() {
  local exit_code=$1
  local original_shell_options=$2
  local original_trap_exit=$3
  local original_trap_err=$4

  if [[ $exit_code -ne 0 ]]; then
    log_warning "Failed to complete the script, install_prerequisite.sh with exit code $exit_code"
  else
    log_info "Complete the script, install_prerequisite.sh successfully"
  fi

  # Restore the original traps
  restore_trap EXIT "$original_trap_exit"
  restore_trap ERR "$original_trap_err"

  # Restore the original shell options
  eval "$original_shell_options"
}
