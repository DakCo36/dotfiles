#!/usr/bin/env bats
TEST_LOGGER_SCRIPT_DIR_PATH="$(dirname ${BASH_SOURCE[0]})"
LOGGER_SCRIPT_PATH="${TEST_LOGGER_SCRIPT_DIR_PATH}/../../lib/logger.sh"

source $LOGGER_SCRIPT_PATH

function test_get_timestamp_format() {
  timestamp=$(get_timestamp)
  assert_matches '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$' "$timestamp"
}

function test_log_debug_print() {
  LOG_LEVEL=${LOG_LEVEL_DEBUG}
  log=$(log_debug "This is a debug message")
  assert_matches '^.+?[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} \[DEBUG\].+? This is a debug message$' "$log"
}

function test_log_debug_not_shown {
  LOG_LEVEL=${LOG_LEVEL_INFO}
  log=$(log_debug "This debug message should not be shown")
  assert_matches '' "$log"
}

function test_log_info_print() {
  LOG_LEVEL=${LOG_LEVEL_INFO}
  log=$(log_info "This is an info message")
  assert_matches '^.+?[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} \[INFO\].+? This is an info message$' "$log"
}

function test_log_info_not_shown {
  LOG_LEVEL=${LOG_LEVEL_WARNING}
  log=$(log_info "This info message should not be shown")
  assert_matches '' "$log"
}

function test_log_warning_print() {
  LOG_LEVEL=${LOG_LEVEL_WARNING}
  log=$(log_warning "This is a warning message")
  assert_matches '^.+?[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} \[WARNING\].+? This is a warning message$' "$log"
}

function test_log_warning_not_shown {
  LOG_LEVEL=${LOG_LEVEL_ERROR}
  log=$(log_warning "This warning message should not be shown")
  assert_matches '' "$log"
}

function test_log_error_print() {
  LOG_LEVEL=${LOG_LEVEL_ERROR}
  log=$(log_error "This is an error message")
  assert_matches '^.+?[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} \[ERROR\].+? This is an error message$' "$log"
}
