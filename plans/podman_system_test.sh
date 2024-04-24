#!/usr/bin/env bash

set -exo pipefail

cat /etc/redhat-release
rpm -q container-selinux podman podman-tests

# Run podman system tests
bats /usr/share/podman/test/system/410-selinux.bats
