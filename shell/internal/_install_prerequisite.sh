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
  "git"
  "curl"
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

ROCKY_PACKAGES=(
  "git"
  "curl"
  "autoconf"
  "gcc"
  "make"
  "patch"
  "bzip2"
  "openssl-devel"
  "libffi-devel"
  "readline-devel"
  "zlib-devel"
  "gdbm-devel"
  "ncurses-devel"
  "tar"
  "perl-FindBin"
)

OPENSUSE_PACKAGES=(
  "git"
  "curl"
  "gcc"
  "make"
  "patch"
  "automake"
  "bzip2"
  "libopenssl-devel"
  "libyaml-devel"
  "libffi-devel"
  "readline-devel"
  "zlib-devel"
  "gdbm-devel"
  "ncurses-devel"
)

function install_ubuntu_prerequisite() {
  log_info "Updating package list..."
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

function install_rocky_prerequisite() {
  log_info "Installing Rocky Linux prerequisites..."

  local PACKAGES=("${ROCKY_PACKAGES[@]}")
  local HAS_LIBYAML=0

  # Check if libyaml-devel is already installed
  if rpm -q libyaml-devel &>/dev/null; then
    HAS_LIBYAML=1
    log_info "libyaml-devel is already installed."
  fi

  for package in "${PACKAGES[@]}"; do
    if ! rpm -q "${package}" &>/dev/null; then
      log_info "Installing $package..."
      sudo dnf install -y "$package" &>> "$INSTALL_LOG"
    else
      log_info "$package is already installed."
    fi
  done

  # Special handling for libyaml-devel which might be in CRB repo
  if [[ $HAS_LIBYAML -eq 0 ]]; then
    if ! rpm -q libyaml-devel &>/dev/null; then
      log_info "Installing libyaml-devel (trying CRB repo if needed)..."
      # Try installing normally first, if fails, try enabling CRB
      if ! sudo dnf install -y libyaml-devel &>> "$INSTALL_LOG"; then
        log_info "Standard install failed. Trying with --enablerepo=crb..."
        sudo dnf install -y --enablerepo=crb libyaml-devel &>> "$INSTALL_LOG"
      fi
    else
      log_info "libyaml-devel is already installed."
    fi
  fi
}

function install_opensuse_prerequisite() {
  log_info "Installing OpenSUSE prerequisites..."

  for package in "${OPENSUSE_PACKAGES[@]}"; do
    if ! rpm -q "${package}" &>/dev/null; then
      log_info "Installing $package..."
      sudo zypper install -y "$package" &>> "$INSTALL_LOG"
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

  log_info "Detected OS: $ID"

  case "$ID" in
    ubuntu|debian)
      install_ubuntu_prerequisite
      ;;
    rocky|rhel|centos|fedora)
      install_rocky_prerequisite
      ;;
    opensuse*|sles)
      install_opensuse_prerequisite
      ;;
    *)
      log_error "Unsupported OS: $ID"
      return 1
      ;;
  esac

  cleanup 0 "${ORIGINAL_SHELL_OPTIONS}" "${ORIGINAL_TRAP_EXIT}" "${ORIGINAL_TRAP_ERR}"
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
