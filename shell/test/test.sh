#!/bin/bash

docker build --progress plain --no-cache -t shell-test -f test/Dockerfile .
