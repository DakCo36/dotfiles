#!/bin/bash

source $(dirname $0)/logger.sh
set_log_level $LOG_LEVEL_DEBUG

TIMESTAMP=$(date +%s)
RBENV_DIR="$HOME/.rbenv"
RBENV_GITHUB_URL="https://github.com/rbenv/rbenv.git"
LOG_FILE="/tmp/ruby_install.log"
INSTALL_LOG="$LOG_FILE"
INSTALLING_STEPS=()

rollback() {
  log_error "An error occured. Rolling back changes..."

  for step in "${INSTALLING_STEPS[@]}"; do
    case "$step" in
      "rbenv")
        log_warning "Removing rbenv directory from $RBENV_DIR"
        rm -rf "$RBENV_DIR" || log_warning "Failed to remove rbenv directory from $RBENV_DIR"
        ;;
      *)
        log_warning "Unknown step: $step"
        ;;
    esac
  done
}

install_rbenv() {
  local output
  local exit_code
  # Backup previous installation
  if [[ -d $RBENV_DIR ]]; then
    log_info "Backing up existing rbenv installation..."
    mv "$RBENV_DIR" "$RBENV_DIR.bak.$TIMESTAMP"
    log_info "Backup created at $RBENV_DIR.bak.$TIMESTAMP"
  fi

  # Install rbenv
  INSTALLING_STEPS+=("rbenv")
  log_info "Installing rbenv..."
  output=$(git clone "$RBENV_GITHUB_URL" "$RBENV_DIR" 2>&1)
  exit_code=$?
  log_debug "$output"
  
  if [[ $exit_code -ne 0 ]]; then
    echo "Failed to install rbenv. Check the log at $INSTALL_LOG"
    return 1
  fi

  echo "rbenv installed successfully."
}

main() {
  install_rbenv
  if [[ $? -ne 0 ]]; then
    rollback
    exit 1
  fi
}

main
