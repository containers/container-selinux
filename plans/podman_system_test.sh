#!/usr/bin/env bash

# Copr repo setup handled in common_setup.sh
. ./plans/common_setup.sh

# Run Podman's SELinux system tests
bats /usr/bin/podman /usr/share/podman/test/system/410-selinux.bats
