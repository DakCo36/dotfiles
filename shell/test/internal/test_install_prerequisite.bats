#!/usr/bin/env bats

BATS_DIR="$(dirname ${BATS_TEST_FILENAME})"
BATS_TMPDIR="$(mktemp -d)"
BATS_TEST_LOG="${BATS_TMPDIR}/test.log"

source ${BATS_DIR}/../../internal/_install_prerequisite.sh
load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'

setup() {
  export UBUNTU_PACKAGES=(
    "package1"
    "package2"
    "already_installed_package"
  )

  export ROCKY_PACKAGES=(
    "package1"
    "package2"
    "already_installed_package"
  )

  export OPENSUSE_PACKAGES=(
    "package1"
    "package2"
    "already_installed_package"
  )

  log_debug() { :; }
  log_info() { :; }
  log_warning() { :; }
  log_error() { :; }
}

teardown() {
  rm -rf "${BATS_TMPDIR}"
}

@test "test_install_ubuntu_prerequisite" {
  # Mocking sudo command
  sudo() {
    if [[ "$1" == "apt-get" && "$2" == "update" ]]; then
      echo "Run apt-get update" >> "$BATS_TEST_LOG"
    elif [[ "$1" == "apt-get" && "$2" == "install" ]]; then
      echo "Run apt-get install -y $3" >> "$BATS_TEST_LOG"
    else
      echo "Unknown command: $*" >> "$BATS_TEST_LOG"
    fi
  }
  dpkg() {
    if [[ "$1" == "-l" ]]; then
      echo "already_installed_package"
    fi
  }

  # When
  run install_ubuntu_prerequisite

  # Then
  assert_success
  assert_file_contains "$BATS_TEST_LOG" "Run apt-get update"
}

@test "test_install_rocky_prerequisite" {
  sudo() {
    if [[ "$1" == "dnf" && "$2" == "makecache" ]]; then
      echo "Run dnf makecache" >> "$BATS_TEST_LOG"
    elif [[ "$1" == "dnf" && "$2" == "install" ]]; then
      echo "Run dnf install -y $3" >> "$BATS_TEST_LOG"
    else
      echo "Unknown command: $*" >> "$BATS_TEST_LOG"
    fi
  }

  rpm() {
    if [[ "$1" == "-q" ]]; then
      if [[ "$2" == "already_installed_package" ]]; then
        return 0
      else
        return 1
      fi
    fi
  }

  run install_rocky_prerequisite

  assert_success
  assert_file_contains "$BATS_TEST_LOG" "Run dnf makecache"
  assert_file_contains "$BATS_TEST_LOG" "Run dnf install -y package1"
  assert_file_contains "$BATS_TEST_LOG" "Run dnf install -y package2"
  refute_file_contains "$BATS_TEST_LOG" "already_installed_package"
}

@test "test_install_opensuse_prerequisite" {
  sudo() {
    if [[ "$1" == "zypper" && "$2" == "refresh" ]]; then
      echo "Run zypper refresh" >> "$BATS_TEST_LOG"
    elif [[ "$1" == "zypper" && "$2" == "install" ]]; then
      echo "Run zypper install -y $3" >> "$BATS_TEST_LOG"
    else
      echo "Unknown command: $*" >> "$BATS_TEST_LOG"
    fi
  }

  rpm() {
    if [[ "$1" == "-q" ]]; then
      if [[ "$2" == "already_installed_package" ]]; then
        return 0
      else
        return 1
      fi
    fi
  }

  run install_opensuse_prerequisite

  assert_success
  assert_file_contains "$BATS_TEST_LOG" "Run zypper refresh"
  assert_file_contains "$BATS_TEST_LOG" "Run zypper install -y package1"
  assert_file_contains "$BATS_TEST_LOG" "Run zypper install -y package2"
  refute_file_contains "$BATS_TEST_LOG" "already_installed_package"
}
