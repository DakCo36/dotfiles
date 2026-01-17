#!/bin/bash

# mise installer script
# Replaces rbenv with mise for Ruby version management

if [[ -n "${BASH_SOURCE[0]}" ]]; then
  INSTALL_MISE_SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
else
  INSTALL_MISE_SCRIPT_DIR="$(pwd)"
fi

source "$INSTALL_MISE_SCRIPT_DIR/../lib/utils.sh" || return 1
source "$INSTALL_MISE_SCRIPT_DIR/../lib/logger.sh" || return 1

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$HOME/.backup/install_mise_${TIMESTAMP}"
PATH_BACKUP="$PATH"

# ZSH
ZSHRC="$HOME/.zshrc"
ZPROFILE="$HOME/.zprofile"

# BASH
BASHRC="$HOME/.bashrc"
BASHPROFILE="$HOME/.bash_profile"

# mise
MISE_DIR="$HOME/.local/share/mise"
MISE_BIN="$HOME/.local/bin/mise"

INSTALLING_STEPS=()

RUBY_VERSION="3.4.3"
INSTALL_LOG=$(mktemp /tmp/install_mise.XXXXXX.log)

function prepare() {
  mkdir -p "$BACKUP_DIR"
  mkdir -p "$HOME/.local/bin"

  # Backup existing mise installation if exists
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

  # Backup shell config files
  for file in "$BASHRC" "$BASHPROFILE" "$ZSHRC" "$ZPROFILE"; do
    if [[ -f $file ]]; then
      log_info "Backup $file"
      cp "${file}" "${BACKUP_DIR}/$(basename $file)"
      log_info "Backup created on $BACKUP_DIR/$(basename $file)"
    fi
  done
}

function install_mise_binary() {
  INSTALLING_STEPS+=("install_mise_binary")

  log_info "Installing mise..."
  
  # Download and install mise using the official installer
  curl -fsSL https://mise.run | sh 2>&1

  if [[ ! -f $MISE_BIN ]]; then
    log_error "mise binary not found at $MISE_BIN"
    return 1
  fi

  log_info "mise installed successfully at $MISE_BIN"
  
  # Verify installation
  $MISE_BIN --version
  log_info "mise version verified."
}

function activate_mise_session() {
  INSTALLING_STEPS+=("activate_mise_session")

  log_info "Activating mise in current session..."
  
  # Add mise to PATH for current session
  export PATH="$HOME/.local/bin:$PATH"
  
  # Activate mise in current session
  eval "$($MISE_BIN activate bash)"
  
  log_info "mise activated in current session."
}

function configure_mise_shell() {
  INSTALLING_STEPS+=("configure_mise_shell")

  log_info "Configuring mise for shell..."

  # .bashrc 설정
  # non-interactive에서도 실행되도록 PATH export는 맨 앞에 추가
  # interactive에서만 로딩하도록 mise activate는 맨 끝에 추가
  if ! grep -q 'mise activate' "$BASHRC" 2>/dev/null; then
    log_info "Adding mise configuration to ~/.bashrc..."
    
    if ! grep -q '# mise PATH' "$BASHRC" 2>/dev/null; then
      log_info "Prepending mise PATH to ~/.bashrc (for non-interactive shells)..."
      local tmp_bashrc=$(mktemp)
      {
        echo "# mise PATH - must be before interactive check for non-interactive shells (e.g., IDE)"
        echo 'export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"'
        echo ""
        cat "$BASHRC"
      } > "$tmp_bashrc"
      mv "$tmp_bashrc" "$BASHRC"
    fi
    
    {
      echo ""
      echo "# mise activation - for interactive shells"
      echo 'eval "$(~/.local/bin/mise activate bash)"'
    } >> "$BASHRC"
    log_info "mise configuration added to ~/.bashrc"
  else
    log_info "mise activation already exists in ~/.bashrc"
  fi

  if [[ -f "$ZSHRC" ]]; then
    if ! grep -q 'mise activate' "$ZSHRC" 2>/dev/null; then
      log_info "Adding mise configuration to ~/.zshrc..."
      
      if ! grep -q '# mise PATH' "$ZSHRC" 2>/dev/null; then
        log_info "Prepending mise PATH to ~/.zshrc..."
        local tmp_zshrc=$(mktemp)
        {
          echo "# mise PATH - must be before interactive check for non-interactive shells"
          echo 'export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"'
          echo ""
          cat "$ZSHRC"
        } > "$tmp_zshrc"
        mv "$tmp_zshrc" "$ZSHRC"
      fi
      
      # mise activate를 맨 끝에 추가
      {
        echo ""
        echo "# mise activation - for interactive shells"
        echo 'eval "$(~/.local/bin/mise activate zsh)"'
      } >> "$ZSHRC"
      log_info "mise configuration added to ~/.zshrc"
    else
      log_info "mise activation already exists in ~/.zshrc"
    fi
  fi

  log_info "Shell configuration completed."
}

function install_ruby_version() {
  INSTALLING_STEPS+=("install_ruby_version")

  log_info "Installing Ruby ${RUBY_VERSION} using mise..."
  
  # Install Ruby globally using mise (downloads precompiled binary)
  $MISE_BIN use -g ruby@${RUBY_VERSION}
  
  log_info "Set global Ruby version to ${RUBY_VERSION}"
  
  # Verify Ruby installation
  $MISE_BIN exec ruby@${RUBY_VERSION} -- ruby --version
  
  log_info "Successfully installed Ruby ${RUBY_VERSION}"
}

# Rollback functions
function rollback_install_mise_binary() {
  local exit_code
  
  # Remove mise binary
  if [[ -f $MISE_BIN ]]; then
    rm -f "$MISE_BIN"
  fi
  
  # Remove mise data directory
  if [[ -d $MISE_DIR ]]; then
    rm -rf "$MISE_DIR"
  fi
  
  # Remove mise config
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

function rollback_mise_shell() {
  # Restore shell config files from backup
  for file in "$BASHRC" "$BASHPROFILE" "$ZSHRC" "$ZPROFILE"; do
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
      "install_mise_binary")
        log_info "Rollback, removing mise binary"
        rollback_install_mise_binary
        ;;
      "configure_mise_shell"|"activate_mise_session")
        log_info "Rollback, restoring shell configuration"
        rollback_mise_shell
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

function install_mise() {
  # Save original shell options
  local ORIGINAL_SHELL_OPTIONS=$(set +o)
  local ORIGINAL_TRAP_EXIT="$(trap -p EXIT || echo '')"
  local ORIGINAL_TRAP_ERR="$(trap -p ERR || echo '')"

  set -euo pipefail
  trap 'handle_error $? "$LINENO"' ERR
  trap 'cleanup $? "${ORIGINAL_SHELL_OPTIONS}" "${ORIGINAL_TRAP_EXIT}" "${ORIGINAL_TRAP_ERR}"' EXIT

  prepare
  install_mise_binary
  activate_mise_session
  configure_mise_shell
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
    log_warning "Failed to complete the script, install_mise.sh with exit code $exit_code"
    log_warning "Rollback installation..."
    rollback
  else
    log_info "Complete the script, install_mise.sh successfully"
  fi

  # Restore the original traps
  restore_trap EXIT "$original_trap_exit"
  restore_trap ERR "$original_trap_err"

  # Restore the original shell options
  eval "$original_shell_options"
}
