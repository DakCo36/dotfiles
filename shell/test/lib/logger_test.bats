#!/usr/bin/env bats

source ../../lib/logger.sh

load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'

@test "get_timestamp_format" {
  run get_timestamp
  assert_success
  assert_output --regexp '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$'
}

@test "log_debug_test" {
  LOG_LEVEL=${LOG_LEVEL_DEBUG}
  run log_debug "This is a debug message"
  assert_success
  assert_output --regexp '.+?[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} \[DEBUG\].+? This is a debug message$'
}

@test "log_debug_not_shown" {
  LOG_LEVEL=${LOG_LEVEL_INFO}
  run log_debug "This debug message should not be shown"
  assert_success
  assert_output ''
}

@test "log_info_test" {
  LOG_LEVEL=${LOG_LEVEL_INFO}
  run log_info "This is an info message"
  assert_success
  assert_output --regexp '.+?[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} \[INFO\].+? This is an info message$'
}

@test "log_info_not_shown" {
  LOG_LEVEL=${LOG_LEVEL_WARNING}
  run log_info "This info message should not be shown"
  assert_success
  assert_output ''
}
@test "log_warning_test" {
  LOG_LEVEL=${LOG_LEVEL_WARNING}
  run log_warning "This is a warning message"
  assert_success
  assert_output --regexp '.+?[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} \[WARNING\].+? This is a warning message$'
}

@test "log_warning_not_shown" {
  LOG_LEVEL=${LOG_LEVEL_ERROR}
  run log_warning "This warning message should not be shown"
  assert_success
  assert_output ''
}

@test "log_error_test" {
  LOG_LEVEL=${LOG_LEVEL_ERROR}
  run log_error "This is an error message"
  assert_success
  assert_output --regexp '.+?[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} \[ERROR\].+? This is an error message$'
}

