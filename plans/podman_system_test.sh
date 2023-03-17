#!/usr/bin/env bash

. ./plans/common_setup.sh

# Run Podman's SELinux system tests
bats /usr/bin/podman /usr/share/podman/test/system/410-selinux.bats
