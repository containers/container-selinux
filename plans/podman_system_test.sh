#!/usr/bin/env bash

set -eox pipefail

cat /etc/redhat-release
rpm -q container-selinux podman podman-tests
bats /usr/share/podman/test/system/410-selinux.bats
