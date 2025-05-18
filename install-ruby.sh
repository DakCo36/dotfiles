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

RUBY_VERSION="3.4.3"

function prepare() {
  mkdir -p "$BACKUP_DIR"
  if [[ $? -ne 0 ]]; then
    log_error "Failed to create backup directory at $BACKUP_DIR"
    exit 1
  fi
}

function install_rbenv() {
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

function apply_rbenv() {
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

function install_ruby_build() {
  if [[ ! -d "$(rbenv root)/plugins" ]]; then
    log_info "create plugins directory"
    mkdir -p "$(rbenv root)/plugins"
  fi

  if [[ -d "$(rbenv root)/plugins/ruby-build" ]]; then
    log_info "Remove previous ruby-build"
    rm -rf "$(rbenv root)/plugins/ruby-build"
  fi

  log_info "Cloning ruby-build..."
  local git_log
  git_log=$(git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build 2>&1)
  log_debug "$git_log"
}

function install_ruby() {
  local log
  log_info "Installing ruby (${RUBY_VERSION})"
  rbenv install "$RUBY_VERSION"
  exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    log_error "Fail to install ruby"
    return 1
  fi
}

function set_ruby() {
  log_info "Set global ruby version ${RUBY_VERSION}"
  rbenv global "$RUBY_VERSION"
  exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    log_error "Fail to set version ${RUBY_VERSION}"
    return 1
  fi
}

function rollback_install_rbenv() {
  rm -rf "$RBENV_DIR"
  exit_code=$?
  if [[ $exit_code -ne 0 ]]; then
    log_warning "Failed to remove rbenv directory from $RBENV_DIR"
  else
    log_info "Rollback, rbenv directory removed successfully."
  fi
}

function rollback_apply_rbenv() {
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

function rollback_install_ruby_build() {
  if [[ -d "$(rbenv root)/plugins/ruby-build" ]]; then
    log_info "Remove installed ruby-build"
    rm -rf "$(rbenv root)/plugins/ruby-build"
  fi
}
# End of Rollbacks

function rollback() {
  log_error "An error occured. Rolling back changes..."

  for step in "${INSTALLING_STEPS[@]}"; do
    case "$step" in
      "install_rbenv")
        rollback_rbenv
        ;;
      "apply_rbenv")
        rollback_apply_rbenv
        ;;
      "install_ruby_build")
        rollback_install_ruby_build
        ;;
      *)
        log_warning "Unknown step: $step"
        ;;
    esac
  done
}

function run_functions() {
  local runnable=$1

  $runnable
  exit_code=$?
  INSTALLING_STEPS+=("$runnable")
  if [[ $exit_code -ne 0 ]]; then
    log_error "Failed to run $runnable. Check the log at $INSTALL_LOG"
    rollback
    exit 1
  fi
}

function main() {
  prepare
  # Add rollback function to trap
  run_functions install_rbenv
  run_functions apply_rbenv
  run_functions install_ruby_build
  run_functions install_ruby
}

main
