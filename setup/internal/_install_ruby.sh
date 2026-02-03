#!/bin/bash

# Ruby installer script using mise as the version manager

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

BASHRC="$HOME/.bashrc"
BASHPROFILE="$HOME/.bash_profile"

MISE_DIR="$HOME/.local/share/mise"
MISE_BIN="$HOME/.local/bin/mise"

INSTALLING_STEPS=()

RUBY_VERSION="3.4.8"
INSTALL_LOG=$(mktemp /tmp/install_ruby.XXXXXX.log)

function prepare() {
  mkdir -p "$BACKUP_DIR"
  mkdir -p "$HOME/.local/bin"

  if [[ -d $MISE_DIR ]]; then
    log_info "Backup previous mise installation..."
    mv "${MISE_DIR}" "$BACKUP_DIR/$(basename $MISE_DIR)"
    log_info "Backup created on $BACKUP_DIR/$(basename $MISE_DIR)"
  fi

  if [[ -f $MISE_BIN ]]; then
    log_info "Backup previous mise binary..."
    mv "${MISE_BIN}" "$BACKUP_DIR/mise"
    log_info "Backup created on $BACKUP_DIR/mise"
  fi

  for file in "$BASHRC" "$BASHPROFILE"; do
    if [[ -f $file ]]; then
      log_info "Backup $file"
      cp "${file}" "${BACKUP_DIR}/$(basename $file)"
      log_info "Backup created on $BACKUP_DIR/$(basename $file)"
    fi
  done
}

function install_mise() {
  INSTALLING_STEPS+=("install_mise")

  log_info "Installing mise..."
  
  curl -fsSL https://mise.run | sh 2>&1

  if [[ ! -f $MISE_BIN ]]; then
    log_error "mise binary not found at $MISE_BIN"
    return 1
  fi

  log_info "mise installed successfully at $MISE_BIN"
  $MISE_BIN --version
  log_info "mise version verified."
}

function activate_mise_session() {
  INSTALLING_STEPS+=("activate_mise_session")

  log_info "Activating mise in current session..."
  export PATH="$HOME/.local/bin:$PATH"
  eval "$($MISE_BIN activate bash)"
  log_info "mise activated in current session."
}

function configure_shell() {
  INSTALLING_STEPS+=("configure_shell")

  log_info "Configuring shell..."

  # Add local bin PATH (separate from mise)
  if ! grep -q '# local bin' "$BASHPROFILE" 2>/dev/null; then
    log_info "Adding local bin PATH to ~/.bash_profile..."
    
    if [[ -f "$BASHPROFILE" ]]; then
      local tmp_bashprofile=$(mktemp)
      {
        echo '# local bin'
        echo 'export PATH="$HOME/.local/bin:$PATH"'
        echo ""
        cat "$BASHPROFILE"
      } > "$tmp_bashprofile"
      mv "$tmp_bashprofile" "$BASHPROFILE"
    else
      {
        echo '# local bin'
        echo 'export PATH="$HOME/.local/bin:$PATH"'
      } > "$BASHPROFILE"
    fi
    log_info "local bin PATH added to ~/.bash_profile"
  fi

  # Add mise shims PATH (for non-interactive shells like IDE)
  if ! grep -q '# mise shims' "$BASHPROFILE" 2>/dev/null; then
    log_info "Adding mise shims PATH to ~/.bash_profile..."
    
    local tmp_bashprofile=$(mktemp)
    {
      echo '# mise shims'
      echo 'export PATH="$HOME/.local/share/mise/shims:$PATH"'
      echo ""
      cat "$BASHPROFILE"
    } > "$tmp_bashprofile"
    mv "$tmp_bashprofile" "$BASHPROFILE"
    log_info "mise shims PATH added to ~/.bash_profile"
  fi

  log_info "Shell configuration completed."
}

function install_ruby_version() {
  INSTALLING_STEPS+=("install_ruby_version")

  log_info "Installing Ruby ${RUBY_VERSION} using mise..."
  $MISE_BIN use -g ruby@${RUBY_VERSION}
  log_info "Set global Ruby version to ${RUBY_VERSION}"
  
  $MISE_BIN exec ruby@${RUBY_VERSION} -- ruby --version
  log_info "Successfully installed Ruby ${RUBY_VERSION}"
}

function rollback_mise() {
  local exit_code
  
  if [[ -f $MISE_BIN ]]; then
    rm -f "$MISE_BIN"
  fi
  
  if [[ -d $MISE_DIR ]]; then
    rm -rf "$MISE_DIR"
  fi
  
  if [[ -d "$HOME/.config/mise" ]]; then
    rm -rf "$HOME/.config/mise"
  fi
  
  exit_code=$?
  if [[ $exit_code -ne 0 ]]; then
    log_warning "Failed to remove mise installation"
  else
    log_info "Rollback, mise installation removed successfully."
  fi
}

function rollback_shell() {
  for file in "$BASHRC" "$BASHPROFILE"; do
    backup_file="$BACKUP_DIR/$(basename $file)"
    if [[ -f $backup_file ]]; then
      log_info "Restoring $file from backup..."
      mv "$backup_file" "$file"
    fi
  done

  PATH="$PATH_BACKUP"
  log_info "Successfully rolled back shell configuration"
}

function rollback() {
  trap - ERR
  set +e

  log_error "An error occurred. Rolling back changes..."

  for (( idx=${#INSTALLING_STEPS[@]}-1 ; idx>=0 ; idx-- )); do
    step="${INSTALLING_STEPS[$idx]}"
    case "$step" in
      "install_mise")
        log_info "Rollback, removing mise"
        rollback_mise
        ;;
      "configure_shell"|"activate_mise_session")
        log_info "Rollback, restoring shell configuration"
        rollback_shell
        ;;
      "install_ruby_version")
        log_info "Rollback, Ruby version will be removed with mise"
        ;;
      *)
        log_info "No rollbacks for $step"
        ;;
    esac
  done
  exit 1
}

function install_ruby() {
  local ORIGINAL_SHELL_OPTIONS=$(set +o)
  local ORIGINAL_TRAP_EXIT="$(trap -p EXIT || echo '')"
  local ORIGINAL_TRAP_ERR="$(trap -p ERR || echo '')"

  set -euo pipefail
  trap 'handle_error $? "$LINENO"' ERR
  trap 'cleanup $? "${ORIGINAL_SHELL_OPTIONS}" "${ORIGINAL_TRAP_EXIT}" "${ORIGINAL_TRAP_ERR}"' EXIT

  prepare
  install_mise
  activate_mise_session
  configure_shell
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

  restore_trap EXIT "$original_trap_exit"
  restore_trap ERR "$original_trap_err"
  eval "$original_shell_options"
}
