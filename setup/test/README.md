# Shell Installation Test with Docker

This directory contains Docker-based testing for the shell installation script.

## Purpose

Test `install.sh` in a clean Ubuntu 20.04 environment to verify:
- Script runs without errors
- rbenv is properly installed
- Ruby is properly installed
- PATH is correctly configured

## Usage

Run from the `shell` directory:

```bash
cd /path/to/dotfiles/shell
docker build -t shell-test -f test/Dockerfile .
```

If the build succeeds, all tests have passed!

To explore the environment interactively:

```bash
docker run -it --rm shell-test
```

## What it tests

1. Runs `install.sh` in a fresh Ubuntu 20.04 container
2. Verifies rbenv is installed and accessible
3. Verifies Ruby is installed and accessible
4. Checks that PATH contains rbenv directories

## Files

- `Dockerfile` - Sets up Ubuntu 20.04 test environment
- `test_install.sh` - Runs installation and verification tests
- `README.md` - This file