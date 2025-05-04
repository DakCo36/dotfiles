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
LOG_FILE=""

get_timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

logging_file() {
  local message=$1
  local no_color_message=$(echo "$message" | sed -e "s/\\\\e\[[0-9;]*m//g")
  if [[ -n "$LOG_FILE" ]]; then
    echo "$no_color_message" >> $LOG_FILE
  fi 
}

log_debug() {
  local message="${COLOR_BLUE}$(get_timestamp) [DEBUG]${COLOR_RESET} $1"
  if [[ $LOG_LEVEL -le $LOG_LEVEL_DEBUG ]]; then
    echo -e $message
    logging_file "$message"
  fi
}

log_info() {
  local message="${COLOR_GREEN}$(get_timestamp) [INFO]${COLOR_RESET} $1"
  if [[ $LOG_LEVEL -le $LOG_LEVEL_INFO ]]; then
    echo -e $message
    logging_file "$message"
  fi
}

log_warning() {
  local message="${COLOR_YELLOW}$(get_timestamp) [WARNING]${COLOR_RESET} $1"
  if [[ $LOG_LEVEL -le $LOG_LEVEL_WARNING ]]; then 
    echo -e $message
    logging_file "$message"
  fi
}

log_error() {
  local message="${COLOR_RED}$(get_timestamp) [ERROR]${COLOR_RESET} $1"
  if [[ $LOG_LEVEL -le $LOG_LEVEL_ERROR ]]; then
    echo -e $message
    logging_file "$message"
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
