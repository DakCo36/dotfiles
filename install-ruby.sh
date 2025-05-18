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
BASHRC="$HOME/.bashrc"
BASHPROFILE="$HOME/.bash_profile"

PATH_BACKUP="$PATH"

LOG_FILE="/tmp/ruby_install.$TIMESTAMP.log"
INSTALL_LOG="$LOG_FILE"
INSTALLING_STEPS=()

RUBY_VERSION="3.4.3"

function prepare() {
  mkdir -p "$BACKUP_DIR"
}

function install_rbenv() {
  # Backup previous installation
  if [[ -d $RBENV_DIR ]]; then
    log_info "Backing up existing rbenv installation..."
    mv "$RBENV_DIR" "$RBENV_BACKUP"
    log_info "Backup created at $RBENV_BACKUP"
  fi

  # Install rbenv
  log_info "Installing rbenv..."
  git clone "$RBENV_GITHUB_URL" "$RBENV_DIR" 2>&1
  log_info "rbenv installed successfully."
}

function apply_rbenv() {
  for file in "$BASHRC" "$BASHPROFILE" "$ZSHRC" "$ZPROFILE"; do
    if [[ -f $file ]]; then
      log_info "Backing up existing $file..."
      cp "$file" "$BACKUP_DIR/$(basename $file)"
      log_info "Backup created at $BACKUP_DIR/$(basename $file)"
    fi
  done

  log_info "Applying rbenv to bash and zsh..."
  log_info "Applying on bash..."
  $RBENV_DIR/bin/rbenv init bash --no-rehash 2>&1

  log_info "Applying on zsh..."
  $RBENV_DIR/bin/rbenv init zsh --no-rehash 2>&1

  log_info "Applying on session..."
  eval "$($RBENV_DIR/bin/rbenv init - 2>&1)"

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
  git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build 2>&1
}

function install_ruby() {
  local log
  log_info "Installing ruby (${RUBY_VERSION})"
  rbenv install "$RUBY_VERSION"
}

function set_ruby() {
  log_info "Set global ruby version ${RUBY_VERSION}"
  rbenv global "$RUBY_VERSION"
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

function rollback_apply_rbenv() {
  # Restore .bashrc, .bash_profile, .zshrc, and .zprofile
  for file in "$BASHRC" "$BASHPROFILE" "$ZSHRC" "$ZPROFILE"; do
    backup_file="$BACKUP_DIR/$(basename $file)"
    if [[ -f $backup_file ]]; then
      log_info "Restoring $file from backup..."
      mv "$backup_file" "$file"
    fi
  done

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
  trap - ERR
  set +e

  log_error "An error occured. Rolling back changes..."

  for step in "${INSTALLING_STEPS[@]}"; do
    case "$step" in
      "install_rbenv")
        log_info "Rollback, removing rbenv directory"
        rollback_install_rbenv
        ;;
      "apply_rbenv")
        log_info "Rollback, restoring .zshrc and PATH"
        rollback_apply_rbenv
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

function run_functions() {
  local runnable=$1

  $runnable
  INSTALLING_STEPS+=("$runnable")
}

function cleanup_on_exit() {
  local exit_code=$1
  if [[ $exit_code -eq 0 ]]; then
    log_info "Installation completed successfully."
  else
    log_error "Installation failed with exit code $exit_code."
    rollback
  fi
  set +euo pipefail
  trap - EXIT
  trap - ERR
}

function main() {
  trap 'cleanup_on_exit $?' EXIT
  trap 'rollback' ERR

  prepare
  # Add rollback function to trap
  run_functions install_rbenv
  run_functions apply_rbenv
  run_functions install_ruby_build
  run_functions install_ruby
  run_functions set_ruby
}

set -euo pipefail
main
