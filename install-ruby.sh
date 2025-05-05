#!/bin/bash

source $(dirname $0)/logger.sh
set_log_level $LOG_LEVEL_DEBUG

TIMESTAMP=$(date +%s)
BACKUP_DIR="$HOME/.backup/$TIMESTAMP"

RBENV_DIR="$HOME/.rbenv"
RBENV_GITHUB_URL="https://github.com/rbenv/rbenv.git"
RBENV_BACKUP="$BACKUP_DIR/.rbenv"

ZSHRC="$HOME/.zshrc"
ZSHRC_BACKUP="$BACKUP_DIR/.zshrc"
ZPROFILE="$HOME/.zprofile"
ZPROFILE_BACKUP="$BACKUP_DIR/.zprofile"

PATH_BACKUP="$PATH"

LOG_FILE="/tmp/ruby_install.$TIMESTAMP.log"
INSTALL_LOG="$LOG_FILE"
INSTALLING_STEPS=()

prepare() {
  mkdir -p "$BACKUP_DIR"
  if [[ $? -ne 0 ]]; then
    log_error "Failed to create backup directory at $BACKUP_DIR"
    exit 1
  fi
}

install_rbenv() {
  local output
  local exit_code
  # Backup previous installation
  if [[ -d $RBENV_DIR ]]; then
    log_info "Backing up existing rbenv installation..."
    mv "$RBENV_DIR" "$RBENV_BACKUP"
    log_info "Backup created at $RBENV_BACKUP"
  fi

  # Install rbenv
  INSTALLING_STEPS+=("install_rbenv")
  log_info "Installing rbenv..."
  output=$(git clone "$RBENV_GITHUB_URL" "$RBENV_DIR" 2>&1)
  exit_code=$?
  log_debug "$output"
  
  if [[ $exit_code -ne 0 ]]; then
    log_error "Failed to install rbenv. Check the log at $INSTALL_LOG"
    return 1
  fi

  log_info "rbenv installed successfully."
}

apply_rbenv() {
  local output
  local exit_code
  # Backup existing .zshrc
  if [[ -f $ZSHRC ]]; then
    cp "$ZSHRC" "$ZSHRC_BACKUP"
    log_info "Backup of .zshrc created at $ZSHRC_BACKUP"
  fi
  # Backup existing .zprofile
  if [[ -f $ZPROFILE ]]; then
    cp "$ZPROFILE" "$ZPROFILE_BACKUP"
    log_info "Backup of .zprofile created at $ZPROFILE_BACKUP"
  fi

  INSTALLING_STEPS+=("apply_rbenv")
  log_info "Applying rbenv..."
  output=$($RBENV_DIR/bin/rbenv init zsh --no-rehash 2>&1)
  exit_code=$?
  log_debug "$output"

  if [[ $exit_code -ne 0 ]]; then
    log_error "Failed to apply rbenv. Check the log at $INSTALL_LOG"
    return 1
  fi

  log_info "rbenv applied successfully."
}

# install_ruby_build() {
#   local output
#   local exit_code
#   # Install ruby-build
#   log_info "Installing ruby-build..."
#   output=$(git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build 2>&1)
#   exit_code=$?
# }
# End of Runnable functions

rollback_install_rbenv() {
  rm -rf "$RBENV_DIR"
  exit_code=$?
  if [[ $exit_code -ne 0 ]]; then
    log_warning "Failed to remove rbenv directory from $RBENV_DIR"
  else
    log_info "Rollback, rbenv directory removed successfully."
  fi
}

rollback_apply_rbenv() {
  if [[ -f $ZSHRC_BACKUP ]]; then
    mv "$ZSHRC_BACKUP" "$ZSHRC"
    exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
      log_warning "Failed to restore .zshrc from $ZSHRC_BACKUP"
    else
      log_info "Rollback, .zshrc restored successfully."
    fi
  else
    log_warning "No backup found for .zshrc. Cannot rollback."
  fi

  PATH="$PATH_BACKUP"
  log_info "Rollback, PATH restored successfully."
}



# End of Rollbacks

run_functions() {
  local runnable=$1

  $runnable
  exit_code=$?
  if [[ $exit_code -ne 0 ]]; then
    log_error "Failed to run $runnable. Check the log at $INSTALL_LOG"
    return 1
  fi
}

rollback() {
  log_error "An error occured. Rolling back changes..."

  for step in "${INSTALLING_STEPS[@]}"; do
    case "$step" in
      "install_rbenv")
        rollback_rbenv
        ;;
      "apply_rbenv")
        rollback_apply_rbenv
        ;;
      *)
        log_warning "Unknown step: $step"
        ;;
    esac
  done
}


main() {
  prepare
  # Add rollback function to trap
  run_functions install_rbenv
  run_functions apply_rbenv
}

main
