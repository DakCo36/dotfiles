#!/bin/bash

if [[ -n "${BASH_SOURCE[0]}" ]]; then
  INSTALL_RUBY_SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
else
  INSTALL_RUBY_SCRIPT_DIR="$(pwd)"
fi

source "$INSTALL_RUBY_SCRIPT_DIR/../lib/utils.sh" || return 1
source "$INSTALL_RUBY_SCRIPT_DIR/../lib/logger.sh" || return 1

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$HOME/.backup/install_ruby_${TIMESTAMP}"
PATH_BACKUP="$PATH"

# ZSH
ZSHRC="$HOME/.zshrc"
ZPROFILE="$HOME/.zprofile"

# BASH
BASHRC="$HOME/.bashrc"
BASHPROFILE="$HOME/.bash_profile"

# Ruby
RBENV_DIR="$HOME/.rbenv"
RBENV_GITHUB_URL="https://github.com/rbenv/rbenv.git"

INSTALLING_STEPS=()

RUBY_VERSION="3.4.3"
INSTALL_LOG=$(mktemp /tmp/install_ruby.XXXXXX.log)

function prepare() {
  mkdir -p "$BACKUP_DIR"

  if [[ -d $RBENV_DIR ]]; then
    log_info "Backup previous rbenv installation..."
    mv "${RBENV_DIR}" "$BACKUP_DIR/$(basename $RBENV_DIR)"
    log_info "Backup created on "$BACKUP_DIR/$(basename $RBENV_DIR)""
  fi

  for file in "$BASHRC" "$BASHPROFILE" "$ZSHRC" "$ZPROFILE"; do
    if [[ -f $file ]]; then
      log_info "Backup $file"
      cp "${file}" "${BACKUP_DIR}/$(basename $file)"
      log_info "Backup created on $BACKUP_DIR/$(basename $file)"
    fi
  done
}

function install_rbenv() {
  INSTALLING_STEPS+=("install_rbenv")

  log_info "Installing rbenv..."
  git clone "$RBENV_GITHUB_URL" "$RBENV_DIR" 2>&1
  log_info "rbenv installed successfully."
  
  log_info "Applying on session..."
  eval "$($RBENV_DIR/bin/rbenv init - 2>&1)"

  log_info "Applying on bash..."

  # Check if rbenv is already in ~/.bashrc
  if ! grep -q "$RBENV_DIR/bin" ~/.bashrc; then
    log_info "Adding rbenv to PATH in ~/.bashrc..."
    sed -i "1i # Added by rbenv installation\nexport PATH=\"$RBENV_DIR/bin:\$PATH\"\n" ~/.bashrc
    log_info "rbenv PATH added at the beginning of ~/.bashrc"
  else
    log_info "rbenv PATH already exists in ~/.bashrc"
  fi

  # Add rbenv init to bashrc
  if ! grep -q 'rbenv init' ~/.bashrc; then
    sed -i '3i # eval rbenv\neval "$(rbenv init - --no-rehash bash)"' ~/.bashrc
    log_info "rbenv init added to ~/.bashrc"
  fi

  log_info "Successfully, rbenv installed"
}

function install_ruby_build() {
  INSTALLING_STEPS+=("install_ruby_build")

  log_info "Installing ruby build..."
  if [[ ! -d "$(rbenv root)/plugins" ]]; then
    log_info "create plugins directory"
    mkdir -p "$(rbenv root)/plugins"
  fi

  if [[ -d "$(rbenv root)/plugins/ruby-build" ]]; then
    log_info "Remove previous ruby-build"
    rm -rf "$(rbenv root)/plugins/ruby-build"
  fi

  log_info "Cloning ruby-build..."
  git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build 2>&1

  log_info "Successfully, ruby_build installed"
}

function install_ruby_version() {
  INSTALLING_STEPS+=("install_ruby_version")
  log_info "Installing ruby (${RUBY_VERSION})"
  rbenv install "$RUBY_VERSION"

  log_info "Set global ruby version ${RUBY_VERSION}"
  rbenv global "$RUBY_VERSION"

  log_info "Successfully, ruby(${RUBY_VERSION}) installed"
}

function rollback_install_rbenv() {
  local exit_code
  rm -rf "$RBENV_DIR"
  exit_code=$?
  if [[ $exit_code -ne 0 ]]; then
    log_warning "Failed to remove rbenv directory from $RBENV_DIR"
  else
    log_info "Rollback, rbenv directory removed successfully."
  fi
}

function rollback_rbenv() {
  # Restore .bashrc, .bash_profile, .zshrc, and .zprofile
  for file in "$BASHRC" "$BASHPROFILE" "$ZSHRC" "$ZPROFILE"; do
    backup_file="$BACKUP_DIR/$(basename $file)"
    if [[ -f $backup_file ]]; then
      log_info "Restoring $file from backup..."
      mv "$backup_file" "$file"
    fi
  done

  PATH="$PATH_BACKUP"
  log_info "Successfully, rollback install_rbenv"
}

function rollback_ruby_build() {
  if [[ -d "$(rbenv root)/plugins/ruby-build" ]]; then
    log_info "Remove installed ruby-build"
    rm -rf "$(rbenv root)/plugins/ruby-build"
  fi

  log_info "Successfully, rollback install_ruby_build"
}
# End of Rollbacks

function rollback() {
  trap - ERR
  set +e

  log_error "An error occured. Rolling back changes..."

  for (( idx=${#INSTALLING_STEPS[@]}-1 ; idx>=0 ; idx-- )); do
    step="${INSTALLING_STEPS[$idx]}"
    case "$step" in
      "install_rbenv")
        log_info "Rollback, removing rbenv directory"
        rollback_install_rbenv
        ;;
      "install_ruby_build")
        log_info "Rollback, removing ruby-build"
        rollback_install_ruby_build
        ;;
      *)
        log_info "No rollbacks for $step"
        ;;
    esac
  done
  exit 1
}

function install_ruby() {
  # Save original shell options
  local ORIGINAL_SHELL_OPTIONS=$(set +o)
  local ORIGINAL_TRAP_EXIT="$(trap -p EXIT || echo '')"
  local ORIGINAL_TRAP_ERR="$(trap -p ERR || echo '')"

  set -euo pipefail
  trap 'handle_error $? "$LINENO"' ERR
  trap 'cleanup $? "${ORIGINAL_SHELL_OPTIONS}" "${ORIGINAL_TRAP_EXIT}" "${ORIGINAL_TRAP_ERR}"' EXIT

  prepare
  install_rbenv
  install_ruby_build
  install_ruby_version

  cleanup 0 "${ORIGINAL_SHELL_OPTIONS}" "${ORIGINAL_TRAP_EXIT}" "${ORIGINAL_TRAP_ERR}"
  return 0
}

function cleanup() {
  local exit_code=$1
  local original_shell_options=$2
  local original_trap_exit=$3
  local original_trap_err=$4

  if [[ $exit_code -ne 0 ]]; then
    log_warning "Failed to complete the script, install_ruby.sh with exit code $exit_code"
    log_warning "Rollback installation..."
    rollback
  else
    log_info "Complete the script, install_ruby.sh successfully"
  fi

  # Restore the original traps
  restore_trap EXIT "$original_trap_exit"
  restore_trap ERR "$original_trap_err"

  # Restore the original shell options
  eval "$original_shell_options"
}
