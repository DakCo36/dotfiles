#!/bin/bash

# log level constants
LOG_LEVEL_DEBUG=0
LOG_LEVEL_INFO=1
LOG_LEVEL_WARNING=2
LOG_LEVEL_ERROR=3

# Color codes for logging
COLOR_RESET="\e[0m"
COLOR_RED="\e[31m"
COLOR_YELLOW="\e[33m"
COLOR_GREEN="\e[32m"
COLOR_BLUE="\e[34m"

LOG_LEVEL=${LOG_LEVEL:-$LOG_LEVEL_INFO}

get_timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

log_debug() {
  if [[ $LOG_LEVEL -le $LOG_LEVEL_DEBUG ]]; then
    printf "${COLOR_BLUE}%s [DEBUG] ${COLOR_RESET}%s\n" "$(get_timestamp)" "$1"
  fi
}

log_info() {
  if [[ $LOG_LEVEL -le $LOG_LEVEL_INFO ]]; then
    printf "${COLOR_GREEN}%s [INFO] ${COLOR_RESET}%s\n" "$(get_timestamp)" "$1"
  fi
}

log_warning() {
  if [[ $LOG_LEVEL -le $LOG_LEVEL_WARNING ]]; then 
    printf "${COLOR_YELLOW}%s [WARNING] ${COLOR_RESET}%s\n" "$(get_timestamp)" "$1"
  fi
}

log_error() {
  if [[ $LOG_LEVEL -le $LOG_LEVEL_ERROR ]]; then
    printf "${COLOR_RED}%s [ERROR] ${COLOR_RESET}%s\n" "$(get_timestamp)" "$1"
  fi
}

set_log_level() {
  LOG_LEVEL="$1"
  if ! [[ "$LOG_LEVEL" =~ ^[0-3]$ ]]; then
    printf "${COLOR_RED}%s [ERROR] ${COLOR_RESET}Invalid log level: $1\n"
    printf "${COLOR_RED}$s [ERROR] ${COLOR_RESET}Set log level INFO(${LOG_LEVEL_INFO})\n"
    LOG_LEVEL=1
    return 1
  fi

  return 0
}
